module "cost_usage_report" {

  source = "../../modules/cost_usage_report"

  providers = {
    aws.us-east-1          = aws.us-east-1
    aws.bucket-replication = aws
  }

  application_name = var.environment.application_name
  account_number   = var.environment.account_id
  environment      = var.environment.environment
  tags             = merge(local.tags)

}