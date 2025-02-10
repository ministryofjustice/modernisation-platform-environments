#tfsec:ignore:avd-aws-0088 - The bucket policy is attached to the bucket
#tfsec:ignore:avd-aws-0132 - The bucket policy is attached to the bucket
module "cica_dms_egress_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "mojap-ingestion-${local.environment}-cica-dms-egress"

  force_destroy = true

  versioning = {
    enabled = true
  }

  attach_policy = true
  policy        = data.aws_iam_policy_document.cica_dms_egress_bucket_policy.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_cica_dms_egress_kms[0].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  count = local.environment == "production" ? 1 : 0
}

data "aws_iam_policy_document" "cica_dms_egress_bucket_policy" {
  statement {
    sid    = "ReplicationPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::593291632749:role/mojap-data-production-cica-dms-egress-production"]
    }
    actions = [
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:ReplicateDelete"
    ]
    resources = ["arn:aws:s3:::mojap-ingestion-production-cica-dms-egress/*"]
  }
}
