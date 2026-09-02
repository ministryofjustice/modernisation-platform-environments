module "iam_role" {
  count = local.is-production ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-role?ref=ba3fd6ded6911e0454092147fe3704171cc05e00" # v6.8.1

  name            = local.component_name
  use_name_prefix = false

  trust_policy_permissions = {
    GitHubAuditLogOIDC = {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      principals = [{
        type        = "Federated"
        identifiers = [module.iam_oidc_provider[0].arn]
      }]
      condition = [
        {
          test     = "StringEquals"
          variable = "oidc-configuration.audit-log.githubusercontent.com:aud"
          values   = ["sts.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "oidc-configuration.audit-log.githubusercontent.com:sub"
          values   = ["https://github.com/${local.global_config.github_enterprise_slug}"]
        }
      ]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    KMSAccess = {
      effect    = "Allow"
      actions   = ["kms:GenerateDataKey"]
      resources = [module.kms_key[0].key_arn]
    }
    S3ObjectAccess = {
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${module.s3_bucket[0].s3_bucket_arn}/*"]
    }
  }
}
