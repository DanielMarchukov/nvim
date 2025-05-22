local overseer = require("overseer")

overseer.register_template({
  name = "Data API",
  builder = function()
    return {
      cmd = { "mvn" },
      args = {
        "spring-boot:run",
        "-Dspring-boot.run.mainClass=org.solidus.data.api.SolidusDataApiApplication",
      },
      env = {
        -- Requires AWS_SECRET_ACCESS_KEY and AWS_DEFAULT_REGION to be set
        AWS_DEFAULT_OUTPUT = "json",
        AWS_DEFAULT_REGION = "us-east-2",
        KAFKA_BOOTSTRAPSERVERS = "localhost:29092",
        OTEL_TRACES_EXPORTER = "jaeger",
      },
      cwd = vim.fn.expand("~") .. "/workspace/solidus-data-api",
      name = "Data API",
      components = { "default" },
    }
  end,
})

overseer.register_template({
  name = "Auth Service",
  builder = function()
    return {
      cmd = { "mvn" },
      args = {
        "spring-boot:run",
        "-Dspring-boot.run.mainClass=org.solidus.auth.AuthServiceApplication",
      },
      env = {
        -- Requires AWS_SECRET_ACCESS_KEY and AWS_DEFAULT_REGION to be set
        AWS_DEFAULT_OUTPUT = "json",
        AWS_DEFAULT_REGION = "us-east-2",
        KAFKA_BOOTSTRAPSERVERS = "localhost:29092",
        OTEL_TRACES_EXPORTER = "jaeger",
      },
      cwd = vim.fn.expand("~") .. "/workspace/solidus-auth-service",
      name = "Auth Service",
      components = { "default" },
    }
  end,
})

overseer.register_template({
  name = "Config Manager",
  builder = function()
    return {
      cmd = { "mvn" },
      args = {
        "spring-boot:run",
        "-Dspring-boot.run.mainClass=org.solidus.configuration.manager.SolidusConfigurationManagerApplication",
      },
      env = {
        -- Requires AWS_SECRET_ACCESS_KEY and AWS_DEFAULT_REGION to be set
        AWS_DEFAULT_OUTPUT = "json",
        AWS_DEFAULT_REGION = "us-east-2",
        KAFKA_BOOTSTRAPSERVERS = "localhost:29092",
        OTEL_TRACES_EXPORTER = "jaeger",
      },
      cwd = vim.fn.expand("~") .. "/workspace/solidus-configuration-manager",
      name = "Config Manager",
      components = { "default" },
    }
  end,
})
