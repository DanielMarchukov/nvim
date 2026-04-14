local M = {}

local function strip_wrapping_quotes(value)
  local first = value:sub(1, 1)
  if (first == "'" or first == '"') and value:sub(-1) == first then
    return value:sub(2, -2)
  end
  return value
end

local function glob_first_non_empty(patterns)
  for _, pattern in ipairs(patterns) do
    local matches = vim.fn.glob(vim.fn.expand(pattern), false, true)
    if #matches > 0 then
      return matches
    end
  end
  return {}
end

local function is_osgi_bundle(jar_path)
  local manifest = vim.fn.system({ "unzip", "-p", jar_path, "META-INF/MANIFEST.MF" })
  if vim.v.shell_error ~= 0 then
    return false
  end
  manifest = manifest:gsub("\r", "")
  return manifest:find("\nBundle%-SymbolicName:", 1, false) ~= nil or vim.startswith(manifest, "Bundle-SymbolicName:")
end

local function add_unique_matches(target, seen, patterns, predicate)
  for _, pattern in ipairs(patterns) do
    for _, match in ipairs(vim.fn.glob(vim.fn.expand(pattern), false, true)) do
      local realpath = (vim.uv or vim.loop).fs_realpath(match) or match
      if not seen[realpath] and (not predicate or predicate(match)) then
        seen[realpath] = true
        table.insert(target, match)
      end
    end
  end
end

function M.github_gradle_env()
  local secrets_path = vim.fn.expand("~/.secrets")
  local file = io.open(secrets_path, "r")
  if not file then
    return nil
  end

  local env = {}
  for line in file:lines() do
    local key, value = line:match("^%s*export%s+(GH_USERNAME|GH_TOKEN)%s*=%s*(.-)%s*$")
    if not key then
      key, value = line:match("^%s*(GH_USERNAME|GH_TOKEN)%s*=%s*(.-)%s*$")
    end

    if key and value and value ~= "" then
      env[key] = strip_wrapping_quotes(value)
    end
  end

  file:close()
  return next(env) and env or nil
end

function M.merge_env(base, extra)
  if not extra then
    return base
  end
  return vim.tbl_extend("force", base or {}, extra)
end

function M.jdtls_bundles()
  local bundles = {}
  local seen = {}

  add_unique_matches(bundles, seen, {
    "$MASON/share/java-debug-adapter/com.microsoft.java.debug.plugin-*.jar",
    "$MASON/share/java-debug-adapter/com.microsoft.java.debug.plugin.jar",
  }, is_osgi_bundle)

  add_unique_matches(bundles, seen, {
    "$MASON/share/java-test/*.jar",
  }, function(jar_path)
    local name = vim.fs.basename(jar_path)
    if name == "com.microsoft.java.test.runner-jar-with-dependencies.jar" or name == "jacocoagent.jar" then
      return false
    end
    return is_osgi_bundle(jar_path)
  end)

  return bundles
end

function M.palantir_java_format_command()
  local candidates = {
    vim.fn.expand("~/.local/bin/palantir-java-format"),
    "/usr/local/bin/palantir-java-format",
  }

  for _, candidate in ipairs(candidates) do
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end

  local system_command = vim.fn.exepath("palantir-java-format")
  return system_command ~= "" and system_command or "palantir-java-format"
end

return M
