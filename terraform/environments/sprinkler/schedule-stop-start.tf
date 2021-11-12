#------------------------------------------------------------------------------
# Schedule stop/start EC2 instances
#------------------------------------------------------------------------------

module "stop_ec2_instance_nights" {
  source                         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git//modules/auto-start/lambda-scheduler-stop-start?ref=terraform-0.12"
  name                           = "stop_ec2_instance_nights"
  cloudwatch_schedule_expression = "cron(0/30 * * * ? *)" # "cron(0 0 ? * FRI *)" # Every Friday at 23:00 GMT
  schedule_action                = "stop"
  spot_schedule                  = "terminate"
  ec2_schedule                   = "true"
  rds_schedule                   = "false"
  autoscaling_schedule           = "false"
  environment_name               = terraform.workspace

  resources_tag = {
    key   = "stop_nights"
    value = "true"
  }
}

module "start_ec2_instance_mornings" {
  source                         = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git//modules/auto-start/lambda-scheduler-stop-start?ref=terraform-0.12"
  name                           = "start_ec2_instance_mornings"
  cloudwatch_schedule_expression = "cron(0/5 * * * ? *)" # "cron(0 8 ? * MON *)" # Every Monday at 8:00 GMT
  schedule_action                = "start"
  autoscaling_schedule           = "false"
  spot_schedule                  = "false"
  ec2_schedule                   = "true"
  rds_schedule                   = "false"
  environment_name               = terraform.workspace

  resources_tag = {
    key   = "stop_nights"
    value = "true"
  }
}

resource "aws_kms_grant" "stop_start_scheduler" {
  key_id            = aws_kms_key.ebs.id
  grantee_principal = module.start_ec2_instance_mornings.lambda_iam_role_arn
  operations        = [
    "Decrypt",
    "DescribeKey",
    "CreateGrant"
  ]
}
