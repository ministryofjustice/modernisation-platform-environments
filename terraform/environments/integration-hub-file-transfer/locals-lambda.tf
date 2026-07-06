locals {
  lambda_cloudwatch_logs_retention_in_days = {
    development = 30
    production  = 400
  }

}