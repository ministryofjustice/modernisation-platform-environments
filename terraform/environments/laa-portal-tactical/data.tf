#### This file can be used to store data specific to the member account ####
data "aws_availability_zones" "available" {}

data "aws_kms_key" "aws_rds" {
  key_id = "arn:aws:kms:eu-west-2:${data.aws_caller_identity.current.account_id}:alias/aws/rds"
}

data "aws_secretsmanager_secret" "cert_arn" {
  arn = "arn:aws:secretsmanager:eu-west-2:464827657497:secret:portal_elb_https_listener_cert-tmZyxq"
}

data "aws_secretsmanager_secret_version" "cert_arn" {
  secret_id = data.aws_secretsmanager_secret.cert_arn.id
}