module "landing_zone_antivirus_check_lambda" {
  source = "./modules/lambdas/container-image"

  enable_lambda      = local.landing_zone_antivirus_check_lambda_enable
  image_uri          = "${aws_ecr_repository.file_transfer_in_clamav_scanner.repository_url}:${local.landing_zone_antivirus_check_lambda_version}"
  name               = "${local.project}-landing-zone-check"
  tracing            = "Active"
  lambda_trigger     = true
  trigger_bucket_arn = module.s3_landing_bucket.bucket_arn
  policies           = ["arn:aws:iam::${local.account_id}:policy/${local.s3_read_write_policy}"]

  memory_size                    = local.landing_zone_antivirus_check_lambda_memory_size
  timeout                        = local.landing_zone_antivirus_check_lambda_timeout
  ephemeral_storage_size         = local.landing_zone_antivirus_check_lambda_ephemeral_storage_size # Can be increased up to 10240MB if required
  reserved_concurrent_executions = local.landing_zone_antivirus_check_lambda_concurrent_executions
  log_retention_in_days          = local.landing_zone_antivirus_check_log_retention_in_days

  env_vars = {
    S3_OUTPUT_BUCKET_PATH     = "s3://${module.s3_landing_processing_bucket.bucket_id}"
    S3_QUARANTINE_BUCKET_PATH = "s3://${module.s3_quarantine_bucket.bucket_id}"
  }

  vpc_settings = {
    subnet_ids         = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
    security_group_ids = [aws_security_group.lambda_generic[0].id, ]
  }

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.project}-landing-zone-check"
      Resource_Type = "Lambda"
      Jira          = "DPR2-1499"
    }
  )
}