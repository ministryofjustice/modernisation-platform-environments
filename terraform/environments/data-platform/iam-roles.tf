module "github_actions_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.22.0"

  name = "${local.application_name}-github-actions"

  subjects = ["ministryofjustice/data-platform:*"]

  policies = {
    "github-actions" = module.github_actions_iam_policy.arn
  }

  tags = local.tags
}
