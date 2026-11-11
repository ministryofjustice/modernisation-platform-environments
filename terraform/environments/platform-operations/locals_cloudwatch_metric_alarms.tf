locals {
  lambda_alarms = {
    development = {}
    production = {
      github-actions-trigger-lambda-error-count                 = module.baseline_presets.cloudwatch_metric_alarms.lambda["lambda-error-count"],
      github-project-issue-generator-trigger-lambda-error-count = module.baseline_presets.cloudwatch_metric_alarms.lambda["lambda-error-count"]
    }
  }
}
