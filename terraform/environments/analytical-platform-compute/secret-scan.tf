data "aws_iam_policy_document" "github_actions_secret_check" {
  count = local.is-test ? 1 : 0

  statement {
    sid    = "AllowSecretsManagerList"
    effect = "Allow"

    actions = [
      "secretsmanager:ListSecrets"
    ]

    resources = ["*"]
  }
}

module "github_actions_secret_check_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = local.is-test ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.1"

  name_prefix = "github-actions-secret-check"
  description = "IAM policy for checking AWS Secrets Manager expiry tags"
  policy      = data.aws_iam_policy_document.github_actions_secret_check[0].json

  tags = local.tags
}

module "github_actions_secret_check_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = local.is-test ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  name            = "github-actions-secret-check"
  use_name_prefix = false

  trust_policy_permissions = {
    TrustManagementProductionRole = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-management-production"]}:role/github-actions-secret-check"
        ]
      }]
    }
  }

  policies = {
    github_actions_secret_check = module.github_actions_secret_check_iam_policy[0].arn
  }

  tags = local.tags
}