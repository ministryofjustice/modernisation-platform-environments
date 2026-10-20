locals {
  lambda_alarms = {
    development = {
      github-project-issue-generator-trigger-lambda-error-count = module.baseline_presets.cloudwatch_metric_alarms.lambda["lambda-error-count"]
    }

    production = {
      github-actions-trigger-lambda-error-count = module.baseline_presets.cloudwatch_metric_alarms.lambda["lambda-error-count"]
    }
  }
}
