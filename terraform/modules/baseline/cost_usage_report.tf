module "cost_usage_report" {
  count = var.options.enable_cost_usage_report == true ? 1 : 0

  source = "../../modules/cost_usage_report"

  providers = {
    aws.us-east-1          = aws.us-east-1
    aws.bucket-replication = aws
  }

  application_name = var.environment.application_name
  account_number   = var.environment.account_id
  environment      = var.environment.environment
  tags             = local.tags
}
