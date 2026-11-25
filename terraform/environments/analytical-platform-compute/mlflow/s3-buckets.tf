module "mlflow_bucket" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0


  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=65413ddedcd584e8e7601bc72792a827ec773c23" # v5.18.0

  bucket = "mojap-compute-${local.environment}-mlflow"

  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.mlflow_s3_kms[0].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = local.tags
}
