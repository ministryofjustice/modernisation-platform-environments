module "inspector-sbom-ec2" {
  source                          = "./modules/lambda"
  account_number                  = local.environment_management.account_ids[terraform.workspace]
  project_name                    = local.project_name
  tags                            = local.tags
  region                          = data.aws_region.current.name
  environment                     = local.environment
  lambda_role                     = local.inspector-sbom-ec2-role
  lambda                          = local.inspector-sbom-ec2
  cloudwatch_log_group_kms_key_id = module.kms.key_arn
}

#EventBridge Scheduler to regularly invoke Lambda
resource "aws_eventbridge_schedule" "daily_export" {
  name                = "sbom-daily-schedule"
  description         = "Trigger SBOM export daily"
  schedule_expression = "rate(7 days)" # Modify as needed
  flexible_time_window {
    mode = "OFF"
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.inspector-sbom-ec2.function_name
  principal     = "scheduler.amazonaws.com"
  source_arn    = aws_eventbridge_schedule.daily_export.arn
}

resource "aws_eventbridge_target" "sbom_target" {
  rule  = aws_eventbridge_schedule.daily_export.name
  arn   = module.inspector-sbom-ec2.arn
  input = jsonencode({}) # Add payload with filters if needed
}

### todo moj probably have this covered
# 6. Enable Inspector2 with SBOM auto-enable
#resource "aws_inspector2_enabler" "enable_inspector" {
#  account_ids   = [data.aws_caller_identity.current.account_id]
#  resource_types = ["EC2"]
#}

#resource "aws_inspector2_organization_configuration" "org_config" {
#  auto_enable {
#    ec2 = true
#  }
#}
