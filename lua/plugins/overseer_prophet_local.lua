-- Local-only Prophet Overseer tasks.
return {
  "stevearc/overseer.nvim",
  opts = function(_, opts)
    local overseer = require("overseer")
    local util = require("lspconfig.util")

    local DEFAULT_COMPONENTS = { "default" }
    local PROPHET_ROOT = vim.fn.expand(vim.env.PROPHET_ROOT or "~/repos/prophet-pricing-core")
    local PROPHET_BUILD_EXCLUDES = { "-x", "test", "-x", "spotlessCheck" }
    local PROPHET_ACCEPTANCE_TARGETS = {
      "localAcceptanceTest",
      "localAcceptanceTestFX",
      "localAcceptanceTestEI",
      "localAcceptanceTestMH",
      "localAcceptanceTestSwaps",
      "localAcceptanceTestVSP",
      "reliabilityAcceptanceTest",
      "envswitchverification",
    }

    if vim.fn.isdirectory(PROPHET_ROOT) == 0 then
      return
    end

    local function prophet_root()
      local current_file = vim.fn.expand("%:p")
      local root = current_file ~= "" and util.root_pattern("settings.gradle", "settings.gradle.kts", "gradlew", ".git")(current_file)
        or nil
      if root then
        return root
      end
      return util.root_pattern("settings.gradle", "settings.gradle.kts", "gradlew", ".git")(vim.fn.getcwd()) or PROPHET_ROOT
    end

    local function current_gradle_module(root)
      local current = vim.fn.expand("%:p:h")
      if current == "" or not root then
        return nil
      end

      local module_dir = util.search_ancestors(current, function(path)
        if path == root then
          return path
        end
        if vim.fn.filereadable(path .. "/build.gradle") == 1 or vim.fn.filereadable(path .. "/build.gradle.kts") == 1 then
          return path
        end
      end)

      if not module_dir or module_dir == root or not vim.startswith(module_dir, root .. "/") then
        return nil
      end

      return ":" .. module_dir:sub(#root + 2):gsub("/", ":")
    end

    local function current_gradle_module_path(root)
      local module = current_gradle_module(root)
      return module and module:sub(2):gsub(":", "/") or nil
    end

    local function prophet_module_paths(root)
      local module_paths = {}
      local seen = {}
      local build_files = {}
      vim.list_extend(build_files, vim.fn.globpath(root, "**/build.gradle", false, true))
      vim.list_extend(build_files, vim.fn.globpath(root, "**/build.gradle.kts", false, true))
      table.sort(build_files)

      for _, build_file in ipairs(build_files) do
        local module_dir = vim.fn.fnamemodify(build_file, ":h")
        if module_dir ~= root and vim.startswith(module_dir, root .. "/") then
          local rel = module_dir:sub(#root + 2)
          if rel ~= "buildSrc" and not seen[rel] then
            seen[rel] = true
            table.insert(module_paths, rel)
          end
        end
      end

      return module_paths
    end

    local function prophet_module_path_to_gradle(module_path)
      if not module_path or module_path == "" or module_path == "." then
        return nil
      end

      local normalized = module_path:gsub("^%./", ""):gsub("/$", "")
      if vim.startswith(normalized, ":") then
        return normalized
      end
      return ":" .. normalized:gsub("/", ":")
    end

    local function prophet_module_exists(root, module_path)
      if not root or not module_path or module_path == "" then
        return false
      end

      local module_dir = root .. "/" .. module_path
      return vim.fn.filereadable(module_dir .. "/build.gradle") == 1
        or vim.fn.filereadable(module_dir .. "/build.gradle.kts") == 1
    end

    local function shell_join(args)
      return table.concat(vim.tbl_map(vim.fn.shellescape, args), " ")
    end

    local function prophet_gradle_task(args)
      local root = prophet_root()
      local gradle_cmd = shell_join(vim.list_extend({ "./gradlew" }, vim.deepcopy(args)))
      local shell_cmd = table.concat({
        'if [ -f "$HOME/.secrets" ]; then source "$HOME/.secrets"; fi',
        'if [ -z "${GH_USERNAME:-}" ] || [ -z "${GH_TOKEN:-}" ]; then',
        'echo "Missing GH_USERNAME or GH_TOKEN in ~/.secrets" >&2',
        "exit 1",
        "fi",
        "export GH_USERNAME GH_TOKEN",
        "exec " .. gradle_cmd,
      }, "; ")
      return {
        cmd = { "zsh" },
        args = { "-lc", shell_cmd },
        cwd = root,
        components = DEFAULT_COMPONENTS,
      }
    end

    local function start_overseer_task(task_defn)
      local task = overseer.new_task(task_defn)
      task:start()
      return task
    end

    local function prophet_selected_module_params()
      local root = prophet_root()
      local choices = prophet_module_paths(root)
      return {
        module = {
          type = "enum",
          desc = "Gradle module relative to prophet-pricing-core root",
          choices = choices,
          default = current_gradle_module_path(root) or choices[1],
        },
      }
    end

    local function prophet_module_completion(arg_lead)
      local choices = prophet_module_paths(prophet_root())
      return vim.tbl_filter(function(choice)
        return vim.startswith(choice, arg_lead)
      end, choices)
    end

    local function resolve_prophet_module_path(arg)
      local root = prophet_root()
      local module_path = arg ~= "" and arg or current_gradle_module_path(root)
      if not module_path then
        vim.notify("No module provided and current buffer is not inside a Gradle module", vim.log.levels.ERROR)
        return nil, nil
      end
      if not prophet_module_exists(root, module_path) then
        vim.notify("Unknown Prophet module: " .. module_path, vim.log.levels.ERROR)
        return nil, nil
      end
      return root, module_path
    end

    local function create_prophet_module_command(name, desc, task_args_builder)
      vim.api.nvim_create_user_command(name, function(command_opts)
        local root, module_path = resolve_prophet_module_path(command_opts.args)
        if not root then
          return
        end

        local module = prophet_module_path_to_gradle(module_path)
        start_overseer_task({
          cmd = { "zsh" },
          args = {
            "-lc",
            table.concat({
              'if [ -f "$HOME/.secrets" ]; then source "$HOME/.secrets"; fi',
              'if [ -z "${GH_USERNAME:-}" ] || [ -z "${GH_TOKEN:-}" ]; then',
              'echo "Missing GH_USERNAME or GH_TOKEN in ~/.secrets" >&2',
              "exit 1",
              "fi",
              "export GH_USERNAME GH_TOKEN",
              "exec " .. shell_join(vim.list_extend({ "./gradlew" }, task_args_builder(module))),
            }, "; "),
          },
          cwd = root,
          components = DEFAULT_COMPONENTS,
        })
      end, {
        nargs = "?",
        complete = prophet_module_completion,
        desc = desc,
      })
    end

    local function register_prophet_selected_module_template(name, task_args_builder)
      overseer.register_template({
        name = name,
        params = prophet_selected_module_params,
        builder = function(params)
          local module = prophet_module_path_to_gradle(params.module)
          return prophet_gradle_task(task_args_builder(module))
        end,
        condition = {
          dir = PROPHET_ROOT,
        },
      })
    end

    local function register_prophet_current_module_template(name, fallback_args, task_args_builder)
      overseer.register_template({
        name = name,
        builder = function()
          local root = prophet_root()
          local module = current_gradle_module(root)
          local args = module and task_args_builder(module) or fallback_args
          return prophet_gradle_task(args)
        end,
        condition = {
          dir = PROPHET_ROOT,
        },
      })
    end

    local function prophet_clean_build_args(module)
      return { module .. ":clean", module .. ":build", table.unpack(PROPHET_BUILD_EXCLUDES) }
    end

    local function prophet_clean_args(module)
      return { module .. ":clean" }
    end

    local function prophet_test_args(module)
      return { module .. ":test" }
    end

    register_prophet_selected_module_template("Prophet: Clean & Build Selected Module", prophet_clean_build_args)
    register_prophet_selected_module_template("Prophet: Clean Selected Module", prophet_clean_args)
    register_prophet_selected_module_template("Prophet: Test Selected Module", prophet_test_args)

    overseer.register_template({
      name = "Prophet: Clean & Build All Modules",
      builder = function()
        return prophet_gradle_task({ "clean", "build", table.unpack(PROPHET_BUILD_EXCLUDES) })
      end,
      condition = {
        dir = PROPHET_ROOT,
      },
    })

    overseer.register_template({
      name = "Prophet: Local Acceptance Test",
      builder = function()
        return prophet_gradle_task({ ":acceptance-test:localAcceptanceTest" })
      end,
      condition = {
        dir = PROPHET_ROOT,
      },
    })

    overseer.register_template({
      name = "Prophet: Acceptance Target",
      params = {
        target = {
          type = "enum",
          desc = "Local acceptance-test Gradle target",
          choices = PROPHET_ACCEPTANCE_TARGETS,
          default = "localAcceptanceTest",
        },
      },
      builder = function(params)
        return prophet_gradle_task({ ":acceptance-test:" .. params.target })
      end,
      condition = {
        dir = PROPHET_ROOT,
      },
    })

    overseer.register_template({
      name = "Prophet: Spotless Apply",
      builder = function()
        return prophet_gradle_task({ "spotlessApply" })
      end,
      condition = {
        dir = PROPHET_ROOT,
      },
    })

    register_prophet_current_module_template("Prophet: Current Module Build", { "build" }, function(module)
      return { module .. ":build" }
    end)
    register_prophet_current_module_template("Prophet: Current Module Clean", { "clean" }, prophet_clean_args)
    register_prophet_current_module_template("Prophet: Current Module Test", { "test" }, prophet_test_args)

    if not vim.g.overseer_prophet_commands_loaded then
      vim.g.overseer_prophet_commands_loaded = true
      create_prophet_module_command(
        "ProphetBuild",
        "Clean and build a Prophet Gradle module by repo-relative path",
        prophet_clean_build_args
      )
      create_prophet_module_command("ProphetClean", "Clean a Prophet Gradle module by repo-relative path", prophet_clean_args)
      create_prophet_module_command("ProphetTest", "Test a Prophet Gradle module by repo-relative path", prophet_test_args)
    end
  end,
}
