local overseer = require("overseer")

-- ============================================================================
-- SHARED CONFIGURATION
-- ============================================================================
local workspace = vim.fn.expand("~") .. "/workspace"
local java_home = "/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home"
local jvm_add_opens = "--add-opens=java.base/java.nio=ALL-UNNAMED"

-- Common environment variables for Spring Boot services
-- NOTE: AWS credentials should be set in your shell profile, not hardcoded here
local spring_env = {
  AWS_DEFAULT_OUTPUT = "json",
  AWS_DEFAULT_REGION = "us-east-2",
  KAFKA_BOOTSTRAPSERVERS = "localhost:29092",
  OTEL_TRACES_EXPORTER = "jaeger",
}

-- Helper function to create Spring Boot run configurations
local function spring_boot(name, project, main_class, opts)
  opts = opts or {}
  local args = {
    "spring-boot:run",
    "-Dspring-boot.run.mainClass=" .. main_class,
  }

  if opts.jvm_args then
    table.insert(args, "-Dspring-boot.run.jvmArguments=" .. opts.jvm_args)
  end

  if opts.program_args then
    table.insert(args, "-Dspring-boot.run.arguments=" .. opts.program_args)
  end

  local env = vim.tbl_extend("force", {}, spring_env)
  if opts.env then
    env = vim.tbl_extend("force", env, opts.env)
  end

  overseer.register_template({
    name = name,
    builder = function()
      return {
        cmd = { "mvn" },
        args = args,
        env = env,
        cwd = workspace .. "/" .. project,
        name = name,
        components = { "default" },
      }
    end,
  })
end

-- ============================================================================
-- CORE PLATFORM SERVICES
-- ============================================================================

-- Data API
spring_boot(
  "Data API",
  "solidus-data-api",
  "org.solidus.data.api.SolidusDataApiApplication"
)

-- Auth Service
spring_boot(
  "Auth Service",
  "solidus-auth-service",
  "org.solidus.auth.AuthServiceApplication"
)

-- Config Manager
spring_boot(
  "Config Manager",
  "solidus-configuration-manager",
  "org.solidus.configuration.manager.SolidusConfigurationManagerApplication"
)

-- Client Store
spring_boot(
  "Client Store",
  "solidus-client-store",
  "org.solidus.clientstore.SolidusClientStoreApplication"
)

-- Currency Converter
spring_boot(
  "Currency Converter",
  "solidus-currency-converter",
  "org.solidus.currency.converter.SolidusCurrencyConverterApplication"
)

-- Operations Admin
spring_boot(
  "Operations Admin",
  "solidus-operations-admin",
  "org.solidus.operations.admin.SolidusOperationsAdminApplication"
)

-- REST API
spring_boot(
  "REST API",
  "solidus-rest",
  "org.solidus.rest.SolidusRestApplication"
)

-- Streaming Executor
spring_boot(
  "Streaming Executor",
  "solidus-streaming-executor",
  "org.solidus.streaming.executor.SolidusStreamingExecutorApplication"
)

-- ============================================================================
-- PIPELINE SERVICES
-- ============================================================================

-- Schema Normalizer
spring_boot(
  "Schema Normalizer",
  "solidus-schema-normalizer",
  "org.solidus.normalizer.SolidusSchemaNormalizerApplication"
)

-- Pipeline Enricher
spring_boot(
  "Pipeline Enricher",
  "solidus-pipeline-enricher",
  "org.solidus.pipeline.enricher.SolidusPipelineEnricherApplication",
  {
    env = { AWS_JAVA_V1_DISABLE_DEPRECATION_ANNOUNCEMENT = "true" },
  }
)

-- Batch File Processor
spring_boot(
  "Batch File Processor",
  "solidus-batch-pipeline-file-processor",
  "org.solidus.batch.pipeline.file.processor.SolidusBatchPipelineFileProcessorApplication",
  {
    jvm_args = jvm_add_opens,
    program_args = workspace .. "/TRANSACTION_7ec2d4eb-8d64-4044-ac27-6e21f36983a2.json",
    env = {
      AWS_DEFAULT_REGION = "us-east-1",
      AWS_JAVA_V1_PRINT_LOCATION = "true",
      AWS_JAVA_V1_DISABLE_DEPRECATION_ANNOUNCEMENT = "true",
    },
  }
)

-- ============================================================================
-- MARKET SURVEILLANCE SERVICES
-- ============================================================================

-- MS Algos RT v2
spring_boot(
  "MS Algos RT v2",
  "solidus-ms-algos-rt-v2",
  "org.solidus.ms.algos.rt.SolidusMsAlgosRtV2Application",
  {
    jvm_args = jvm_add_opens,
  }
)

-- MS Batch LAO (Large Action Order)
spring_boot(
  "MS Batch LAO",
  "solidus-ms-algos-batch",
  "org.solidus.ms.batch.MSAlgosBatchApplication",
  {
    jvm_args = jvm_add_opens,
    program_args = "solidusClientId=INTERNAL_BATCH "
      .. "algoName=LARGE_ACTION_ORDER "
      .. "startDate=2025-03-28T00:00 "
      .. "endDate=2025-03-29T00:00 "
      .. "taskId=086c22a7-2f37-4846-85cb-d825fb91d7c2 "
      .. "segmentName=null "
      .. "isPublishAlert=true "
      .. "taskType=ANALYSE",
  }
)

-- MS UnusualVolume (batch algorithm)
overseer.register_template({
  name = "MS UnusualVolume",
  builder = function()
    return {
      cmd = { "mvn" },
      args = {
        "spring-boot:run",
        "-Dspring-boot.run.jvmArguments=" .. jvm_add_opens,
        "-Dspring-boot.run.arguments="
          .. "solidusClientId=INTERNAL_BATCH "
          .. "algoName=UNUSUAL_VOLUME "
          .. "startDate=2025-03-28T00:00 "
          .. "endDate=2025-03-28T12:00 "
          .. "taskId=086c22a7-2f37-4846-85cb-d825fb91d7c2 "
          .. "segmentName=null "
          .. "isPublishAlert=true "
          .. "taskType=ANALYSE",
      },
      cwd = workspace .. "/solidus-ms-algos-batch",
      name = "MS UnusualVolume",
      components = { "default" },
    }
  end,
})

-- MS WashTrade (batch algorithm)
overseer.register_template({
  name = "MS WashTrade",
  builder = function()
    return {
      cmd = { "mvn" },
      args = {
        "spring-boot:run",
        "-Dspring-boot.run.jvmArguments=" .. jvm_add_opens,
        "-Dspring-boot.run.arguments="
          .. "solidusClientId=INTERNAL_BATCH "
          .. "algoName=WASH_TRADE "
          .. "startDate=2025-03-28T00:00 "
          .. "endDate=2025-03-29T00:00 "
          .. "taskId=086c22a7-2f37-4846-85cb-d825fb91d7c2 "
          .. "segmentName=null "
          .. "isPublishAlert=true "
          .. "taskType=ANALYSE",
      },
      cwd = workspace .. "/solidus-ms-algos-batch",
      name = "MS WashTrade",
      components = { "default" },
    }
  end,
})

-- ============================================================================
-- MAVEN BUILD TASKS
-- ============================================================================

-- Kafka Ingest Build (clean install, skip tests)
overseer.register_template({
  name = "Kafka Ingest Build",
  builder = function()
    return {
      cmd = { "mvn" },
      args = { "clean", "install", "-DskipTests=true" },
      env = {
        JAVA_HOME = java_home,
      },
      cwd = workspace .. "/solidus-kafka-ingest",
      name = "Kafka Ingest Build",
      components = { "default" },
    }
  end,
})

-- ============================================================================
-- TEST AUTOMATION
-- ============================================================================

-- Automation Test Suite (TestNG)
overseer.register_template({
  name = "Automation Test Suite",
  builder = function()
    return {
      cmd = { "mvn" },
      args = { "test", "-DsuiteXmlFile=test_suite.xml" },
      env = {
        JAVA_HOME = java_home,
      },
      cwd = workspace .. "/solidus-automation",
      name = "Automation Test Suite",
      components = { "default" },
    }
  end,
})

-- ReplayMessagesIT (integration test)
spring_boot(
  "ReplayMessagesIT",
  "solidus-ms-algos-rt-v2",
  "org.solidus.ms.algos.rt.regression.ReplayMessagesIT",
  {
    jvm_args = jvm_add_opens,
  }
)

-- ============================================================================
-- PYTHON SERVICES
-- ============================================================================

-- Model Serving (Python)
overseer.register_template({
  name = "Model Serving",
  builder = function()
    return {
      cmd = { "python3" },
      args = { "main.py" },
      env = {
        PYTHONUNBUFFERED = "1",
      },
      cwd = workspace .. "/solidus-model-serving",
      name = "Model Serving",
      components = { "default" },
    }
  end,
})

return {}
