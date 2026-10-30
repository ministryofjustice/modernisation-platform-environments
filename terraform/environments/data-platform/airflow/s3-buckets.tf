module "mwaa_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.17.0"

  bucket = "mojdp-${local.environment}-mwaa"

  force_destroy = true

  versioning = {
    enabled = true
  }

  # >>> TEMPORARY (Airflow 3 durability test): START
  attach_policy = length(local.mwaa_bucket_workflow_access) > 0
  policy        = data.aws_iam_policy_document.mwaa_bucket.json
  # <<< TEMPORARY (Airflow 3 durability test): END

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.mwaa_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = local.tags
}

