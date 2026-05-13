locals {
  bucket_list = local.is-production || local.is-preproduction || local.is-test ? [
    module.s3-fms-general-landing-bucket.bucket_arn,
    module.s3-fms-ho-landing-bucket.bucket_arn,
    module.s3-fms-specials-landing-bucket.bucket_arn,
    module.s3-mdss-general-landing-bucket.bucket_arn,
    module.s3-mdss-ho-landing-bucket.bucket_arn,
    module.s3-mdss-specials-landing-bucket.bucket_arn
    ] : local.is-development ? [
    module.s3-fms-general-landing-bucket.bucket_arn,
    module.s3-fms-ho-landing-bucket.bucket_arn,
    module.s3-fms-specials-landing-bucket.bucket_arn,
    module.s3-mdss-general-landing-bucket.bucket_arn,
    module.s3-mdss-ho-landing-bucket.bucket_arn,
    module.s3-mdss-specials-landing-bucket.bucket_arn,
    module.s3-macie-results-bucket[0].bucket_arn
  ] : []
}

module "kms_metadata_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases     = ["s3/metadata_bucket"]
  description = "Metadata bucket KMS key"

  enable_default_policy = true
  key_statements = [
    {
      sid = "CustomKMSForS3"
      actions = [
        "kms:Encrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*"
      ]
      principals = [
        {
          type        = "Service"
          identifiers = ["s3.amazonaws.com"]
        }
      ]
      condition = [
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        },
        {
          test     = "ArnLike"
          variable = "aws:SourceArn"
          values   = locals.bucket_list
        }
      ]
      resources = ["*"]
    }
  ]

  deletion_window_in_days = 7

  tags = local.tags
}
