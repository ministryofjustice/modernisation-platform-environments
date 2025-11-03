#tfsec:ignore:avd-aws-0088 - The bucket policy is attached to the bucket
#tfsec:ignore:avd-aws-0132 - The bucket policy is attached to the bucket
module "cica_dms_ingress_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.8.2"

  bucket = "mojap-ingestion-${local.environment}-cica-dms-ingress"

  force_destroy = true

  versioning = {
    enabled = true
  }

  replication_configuration = {}
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_cica_dms_ingress_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "cica_dms_ingress_bucket_replication" {
  count  = local.environment == "production" ? 1 : 0
  role   = module.production_replication_cica_dms_iam_role[0].iam_role_arn
  bucket = module.cica_dms_ingress_bucket.s3_bucket_id
  rule {
    id     = "mojap-ingestion-cica-dms-ingress"
    status = "Enabled"
    filter {
    }

    delete_marker_replication {
      status = "Enabled"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      account       = "593291632749"
      bucket        = "arn:aws:s3:::mojap-data-production-cica-dms-ingress-production"
      storage_class = "STANDARD"
      access_control_translation {
        owner = "Destination"
      }
      encryption_configuration {
        replica_kms_key_id = "arn:aws:kms:eu-west-2:593291632749:key/8894655b-e02c-46d1-aaa0-c219b31eefb1"
      }
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
    }
  }
}
