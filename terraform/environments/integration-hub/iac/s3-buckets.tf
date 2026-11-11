data "aws_iam_policy_document" "pagerduty_state_bucket" {
  count = local.is-production ? 1 : 0

  statement {
    sid     = "DenyAllExceptAllowedPrincipals"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${local.pagerduty_state_bucket_name}",
      "arn:aws:s3:::${local.pagerduty_state_bucket_name}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values   = local.pagerduty_state_allowed_principal_arns
    }
  }

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${local.pagerduty_state_bucket_name}",
      "arn:aws:s3:::${local.pagerduty_state_bucket_name}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

module "pagerduty_state_bucket" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=0662a7bdfceac73daed7c08df2b421707de341df" # v5.9.0

  bucket        = local.pagerduty_state_bucket_name
  force_destroy = false

  attach_policy = true
  policy        = data.aws_iam_policy_document.pagerduty_state_bucket[0].json

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled       = true
      blocked_encryption_types = ["SSE-C"]
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.pagerduty_state_kms[0].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }

  tags = local.tags
}
