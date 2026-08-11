#trivy:ignore:avd-aws-0132: Skipping because replicating existing bucket that does not encrypt data with a customer managed key
#trivy:ignore:avd-aws-0088: Skipping because has server side encryption
#trivy:ignore:avd-aws-0089: Skipping because access logging is managed externally.
module "ppud" {
  #checkov:skip=CKV_TF_1: Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2: Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.15.3"

  bucket              = "mojap-data-engineering-production-${local.name}-${local.tags["environment-name"]}"
  force_destroy       = false
  object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode = "GOVERNANCE"
        days = 30
      }
    }
    versioning = {
      enabled = true
    }
    server_side_encryption_configuration = {
      rule = {
        bucket_key_enabled = false
        apply_server_side_encryption_by_default = {
          sse_algorithm = "AES256"
        }
      }
    }
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

  attach_policy = true
  policy = jsonencode(
    {
      Statement = [
        {
          Sid    = "Set-permissions-for-objects"
          Effect = "Allow"
          Principal = {
            AWS = [
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/iam_role_s3_bucket_moj_database_source_${local.environment}"
            ]
          }
          Action = [
            "s3:ReplicateObject"
          ]
          Resource = "arn:aws:s3:::mojap-data-engineering-production-ppud-${local.environment}/*"
        },
        {
          Sid    = "Set-permissions-on-buckets"
          Effect = "Allow"
          Principal = {
            AWS = [
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/iam_role_s3_bucket_moj_database_source_${local.environment}"
            ]
          }
          Action = [
            "s3:GetBucketVersioning",
            "s3:PutBucketVersioning"
          ]
          Resource = "arn:aws:s3:::mojap-data-engineering-production-ppud-${local.environment}"
        }
      ]
      Version = "2012-10-17"
    }
  )
  tags = local.tags
}