# to allow bucket inventory, use custom kms key to encrypt s3 bucket
data "aws_iam_policy_document" "metadata_kms_key" {
    statement {
        sid = "CustomKMSForS3"
        actions = [
            "kms:Encrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*"
        ]
        principals {
            type = "Service"
            identifiers = ["s3.amazonaws.com"]

        }
        condition {
            test     = "StringEquals"
            variable = "s3:x-amz-acl"
            values   = ["bucket-owner-full-control"]
        }
        condition {
            test     = "StringEquals"
            variable = "aws:SourceAccount"
            values   = [data.aws_caller_identity.current.account_id]
        }
        condition {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = [
            module.s3-fms-general-landing-bucket.bucket_arn,
            module.s3-fms-ho-landing-bucket.bucket_arn,
            module.s3-fms-specials-landing-bucket.bucket_arn,
            module.s3-mdss-general-landing-bucket.bucket_arn,
            module.s3-mdss-ho-landing-bucket.bucket_arn,
            module.s3-mdss-specials-landing-bucket.bucket_arn,
        ]
        }
        resources = ["*"]
    }
}

module "kms_metadata_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases     = ["s3/metadata_bucket"]
  description = "Metadata bucket KMS key"

  enable_default_policy = true
  policy = data.aws_iam_policy_document.metadata_kms_key.json

  deletion_window_in_days = 7

  tags = local.tags
}
