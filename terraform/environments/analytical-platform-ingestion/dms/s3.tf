#tfsec:ignore:avd-aws-0088 - The bucket policy is attached to the bucket
#tfsec:ignore:avd-aws-0132 - The bucket policy is attached to the bucket
module "cica_dms_ingress_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  count = local.environment == "production" ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "mojap-ingestion-production-cica-dms-ingress"

  force_destroy = true

  versioning = {
    enabled = true
  }

  replication_configuration = {
    role = module.production_replication_cica_dms_iam_role[0].iam_role_arn
    rules = [
      {
        id                        = "mojap-ingestion-cica-dms-ingress"
        status                    = "Enabled"
        delete_marker_replication = true

        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }

        destination = {
          account_id    = "593291632749"
          bucket        = "arn:aws:s3:::mojap-data-production-cica-dms-ingress-production"
          storage_class = "STANDARD"
          access_control_translation = {
            owner = "Destination"
          }
          encryption_configuration = {
            replica_kms_key_id = "arn:aws:kms:eu-west-2:593291632749:key/mrk-27fd90a6ddbc463fb78b0a21592fa8a1"
          }
          metrics = {
            status  = "Enabled"
            minutes = 15
          }
          replication_time = {
            status  = "Enabled"
            minutes = 15
          }
        }
      }
    ]
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_cica_dms_ingress_kms[0].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
