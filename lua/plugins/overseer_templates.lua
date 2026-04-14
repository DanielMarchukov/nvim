-- Cargo and generic Gradle Overseer task templates.
return {
  "stevearc/overseer.nvim",
  opts = function(_, opts)
    local overseer = require("overseer")
    local util = require("lspconfig.util")

    local DEFAULT_COMPONENTS = { "default" }
    local GRADLE_ROOT_PATTERN = util.root_pattern("settings.gradle", "settings.gradle.kts", "gradlew", ".git")

    local function gradle_project_root()
      local current_file = vim.fn.expand("%:p")
      local root = current_file ~= "" and GRADLE_ROOT_PATTERN(current_file) or nil
      if root then
        return root
      end
      return GRADLE_ROOT_PATTERN(vim.fn.getcwd())
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

    local function gradle_module_paths(root)
      if not root then
        return {}
      end

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

    local function gradle_module_completion(arg_lead)
      local choices = gradle_module_paths(gradle_project_root())
      return vim.tbl_filter(function(choice)
        return vim.startswith(choice, arg_lead)
      end, choices)
    end

    local function module_path_to_gradle(module_path)
      if not module_path or module_path == "" or module_path == "." then
        return nil
      end

      local normalized = module_path:gsub("^%./", ""):gsub("/$", "")
      if vim.startswith(normalized, ":") then
        return normalized
      end
      return ":" .. normalized:gsub("/", ":")
    end

    local function module_exists(root, module_path)
      if not root or not module_path or module_path == "" then
        return false
      end

      local module_dir = root .. "/" .. module_path
      return vim.fn.filereadable(module_dir .. "/build.gradle") == 1
        or vim.fn.filereadable(module_dir .. "/build.gradle.kts") == 1
    end

    local function resolve_module_path(arg)
      local root = gradle_project_root()
      if not root then
        vim.notify("Not inside a Gradle project", vim.log.levels.ERROR)
        return nil, nil
      end

      local module_path = arg ~= "" and arg or current_gradle_module_path(root)
      if not module_path then
        return root, nil
      end
      if not module_exists(root, module_path) then
        vim.notify("Unknown Gradle module: " .. module_path, vim.log.levels.ERROR)
        return nil, nil
      end
      return root, module_path
    end

    local function gradle_task(args)
      local root = gradle_project_root()
      if not root then
        return nil
      end

      return {
        cmd = { "./gradlew" },
        args = args,
        cwd = root,
        components = DEFAULT_COMPONENTS,
      }
    end

    local function start_overseer_task(task_defn)
      if not task_defn then
        vim.notify("No Gradle project found", vim.log.levels.ERROR)
        return
      end
      local task = overseer.new_task(task_defn)
      task:start()
      return task
    end

    local function register_gradle_template(name, args_builder)
      overseer.register_template({
        name = name,
        builder = function()
          local root = gradle_project_root()
          local module = current_gradle_module(root)
          local args = args_builder(module)
          return gradle_task(args)
        end,
        condition = {
          callback = function()
            return gradle_project_root() ~= nil
          end,
        },
      })
    end

    local function create_gradle_command(name, desc, args_builder)
      vim.api.nvim_create_user_command(name, function(command_opts)
        local root, module_path = resolve_module_path(command_opts.args)
        if not root then
          return
        end

        local module = module_path_to_gradle(module_path)
        local task = {
          cmd = { "./gradlew" },
          args = args_builder(module),
          cwd = root,
          components = DEFAULT_COMPONENTS,
        }
        start_overseer_task(task)
      end, {
        nargs = "?",
        complete = gradle_module_completion,
        desc = desc,
      })
    end

    overseer.register_template({
      name = "Cargo Build",
      builder = function()
        return {
          cmd = { "cargo" },
          args = { "build" },
          components = DEFAULT_COMPONENTS,
        }
      end,
      condition = {
        filetype = { "rust" },
      },
    })

    overseer.register_template({
      name = "Cargo Build (Release)",
      builder = function()
        return {
          cmd = { "cargo" },
          args = { "build", "--release" },
          components = DEFAULT_COMPONENTS,
        }
      end,
      condition = {
        filetype = { "rust" },
      },
    })

    overseer.register_template({
      name = "Cargo Test",
      builder = function()
        return {
          cmd = { "cargo" },
          args = { "test" },
          components = DEFAULT_COMPONENTS,
        }
      end,
      condition = {
        filetype = { "rust" },
      },
    })

    overseer.register_template({
      name = "Cargo Bench",
      builder = function()
        return {
          cmd = { "cargo" },
          args = { "bench" },
          components = DEFAULT_COMPONENTS,
        }
      end,
      condition = {
        filetype = { "rust" },
      },
    })

    overseer.register_template({
      name = "Cargo Clippy",
      builder = function()
        return {
          cmd = { "cargo" },
          args = { "clippy", "--all-targets", "--", "-W", "clippy::pedantic", "-W", "clippy::nursery" },
          components = DEFAULT_COMPONENTS,
        }
      end,
      condition = {
        filetype = { "rust" },
      },
    })

    overseer.register_template({
      name = "Cargo Doc (Open)",
      builder = function()
        return {
          cmd = { "cargo" },
          args = { "doc", "--open", "--no-deps" },
          components = DEFAULT_COMPONENTS,
        }
      end,
      condition = {
        filetype = { "rust" },
      },
    })

    register_gradle_template("Gradle: Build Project or Current Module", function(module)
      return module and { module .. ":clean", module .. ":build" } or { "clean", "build" }
    end)

    register_gradle_template("Gradle: Clean Project or Current Module", function(module)
      return module and { module .. ":clean" } or { "clean" }
    end)

    register_gradle_template("Gradle: Test Project or Current Module", function(module)
      return module and { module .. ":test" } or { "test" }
    end)

    if not vim.g.overseer_gradle_commands_loaded then
      vim.g.overseer_gradle_commands_loaded = true
      create_gradle_command("Build", "Gradle clean+build for the current module or provided module path", function(module)
        return module and { module .. ":clean", module .. ":build" } or { "clean", "build" }
      end)
      create_gradle_command("Clean", "Gradle clean for the current module or provided module path", function(module)
        return module and { module .. ":clean" } or { "clean" }
      end)
      create_gradle_command("Test", "Gradle test for the current module or provided module path", function(module)
        return module and { module .. ":test" } or { "test" }
      end)
    end
  end,
}
