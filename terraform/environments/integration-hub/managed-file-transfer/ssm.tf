resource "aws_ssm_parameter" "upload_bucket_name" {
  name  = "${local.upload_bucket_parameter_prefix}/name"
  type  = "String"
  value = module.s3_bucket["unscanned"].s3_bucket_id

  tags = local.tags
}

resource "aws_ssm_parameter" "upload_bucket_arn" {
  name  = "${local.upload_bucket_parameter_prefix}/arn"
  type  = "String"
  value = module.s3_bucket["unscanned"].s3_bucket_arn

  tags = local.tags
}

resource "aws_ssm_parameter" "upload_bucket_kms_key_arn" {
  name  = "${local.upload_bucket_parameter_prefix}/kms-key-arn"
  type  = "String"
  value = module.kms_s3_bucket["unscanned"].key_arn

  tags = local.tags
}
