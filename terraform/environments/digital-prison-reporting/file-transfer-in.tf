module "landing_zone_antivirus_check" {
  source = "./modules/lambdas/container-image"

  enable_lambda = true
  image_uri     = "${aws_ecr_repository.file_transfer_in_clamav_scanner.repository_url}:latest"
  name          = "${local.project}-landing-zone-check"
  tracing       = "Active"

  memory_size                    = 4096
  timeout                        = 900
  ephemeral_storage_size         = 512 # Can be increased up to 10240MB if required
  reserved_concurrent_executions = 10

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