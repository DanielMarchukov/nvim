local overseer = require("overseer")

overseer.register_template({
  name = "MS UnusualVolume",
  builder = function()
    return {
      cmd = { "mvn" },
      args = {
        "spring-boot:run",
        "-Dspring-boot.run.jvmArguments=--add-opens=java.base/java.nio=ALL-UNNAMED",
        "-Dspring-boot.run.arguments="
          .. "solidusClientId=INTERNAL_BATCH "
          .. "algoName=UNUSUAL_VOLUME "
          .. "startDate=2025-03-28T00:00 "
          .. "endDate=2025-03-29T00:00 "
          .. "taskId=086c22a7-2f37-4846-85cb-d825fb91d7c2 "
          .. "segmentName=null "
          .. "isPublishAlert=true "
          .. "taskType=ANALYSE",
      },
      cwd = vim.fn.getcwd(),
      name = "MS UnusualVolume",
      components = { "default" },
    }
  end,
})

overseer.register_template({
  name = "MS WashTrade",
  builder = function()
    return {
      cmd = { "mvn" },
      args = {
        "spring-boot:run",
        "-Dspring-boot.run.jvmArguments=--add-opens=java.base/java.nio=ALL-UNNAMED",
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
      cwd = vim.fn.getcwd(),
      name = "MS WashTrade",
      components = { "default" },
    }
  end,
})
