data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_cloudwatch_log_group" "logs" {
  name = var.log_group_name
}

data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}

data "aws_kms_key" "secretsmanager" {
  key_id = "alias/aws/secretsmanager"
}