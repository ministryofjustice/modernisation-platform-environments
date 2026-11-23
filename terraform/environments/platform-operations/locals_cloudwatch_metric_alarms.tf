locals {
  lambda_alarms = {
    development = {}
    production = {
      github-actions-trigger-lambda-error-count = merge(
        module.baseline_presets.cloudwatch_metric_alarms.lambda["lambda-error-count"],
        { dimensions = { FunctionName = "github-actions-trigger" } }
      )
      github-project-issue-generator-trigger-lambda-error-count = merge(
        module.baseline_presets.cloudwatch_metric_alarms.lambda["lambda-error-count"],
        { dimensions = { FunctionName = "github-project-issue-generator-trigger" } }
      )
    }
  }
}
