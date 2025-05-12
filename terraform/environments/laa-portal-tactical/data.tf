#### This file can be used to store data specific to the member account ####
data "aws_availability_zones" "available" {}

data "aws_kms_key" "aws_rds" {
  key_id = "arn:aws:kms:eu-west-2:${data.aws_caller_identity.current.account_id}:alias/aws/rds"
}
