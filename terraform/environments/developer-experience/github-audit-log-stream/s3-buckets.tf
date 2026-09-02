data "aws_iam_policy_document" "s3_bucket" {
  count = local.is-production ? 1 : 0

  statement {
    sid       = "AllowObjectActions"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.bucket_name}/*"]
    principals {
      type        = "AWS"
      identifiers = [module.iam_role[0].arn]
    }
  }
}

module "s3_bucket" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=dd0c434de5e74d8864e249ee020d917b076b6e32" # v5.15.4

  bucket = local.bucket_name

  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.s3_bucket[0].json
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.kms_key[0].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    status = "Enabled"
  }

  lifecycle_rule = [{
    /*
      This lifecycle rule complies with the MOJ’s Security Policy for internal services logging as of 02/09/2026
        - https://justiceuk.sharepoint.com/sites/SecurityPolicyandGuidance/SitePages/Policy%20and%20Guidance/Operations%20Security/Logging-and-Monitoring.aspx#logs-for-internal-services
        - https://justiceuk.sharepoint.com/sites/SecurityPolicyandGuidance/SitePages/Policy%20and%20Guidance/Operations%20Security/Logging-and-Monitoring.aspx#maximum-retention-period
    */
    id     = "retain-github-audit-logs"
    status = "Enabled"

    transition = [
      {
        days          = 90
        storage_class = "STANDARD_IA"
      },
      {
        days          = 395
        storage_class = "GLACIER_IR"
      }
    ]

    expiration = {
      days = 730
    }

    noncurrent_version_transition = [
      {
        noncurrent_days = 90
        storage_class   = "STANDARD_IA"
      },
      {
        noncurrent_days = 395
        storage_class   = "GLACIER_IR"
      }
    ]

    noncurrent_version_expiration = {
      noncurrent_days = 730
    }
  }]
}
