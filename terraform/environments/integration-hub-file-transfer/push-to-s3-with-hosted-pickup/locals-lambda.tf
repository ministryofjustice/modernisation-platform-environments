locals {
  pattern_name     = "ihft-${local.environment}-push-to-s3-hosted-pickup"
  lambda_role_name = local.pattern_name
  lambda_role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.lambda_role_name}"
}