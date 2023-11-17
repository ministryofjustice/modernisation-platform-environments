# CloudWatch Insights, get logs of errored lambdas
# Filter for Lambda Errors with Exception/Error/Fails
module "dpr_cw_insights_lambda_errors" {
  source              = "./modules/cw_insights"
  create_cw_insight   = local.enable_cw_insights

  query_name          = "dpr-cw-insights-lambda-errors"
  log_groups          = ["/aws/lambda"]

  query               = <<EOH
filter @message like /(?i)(Exception|error|fail)/
| fields @timestamp, @message
| sort @timestamp desc
| limit 20
EOH
}
