data "aws_iam_policy_document" "oidc_assume_role" {
  statement {
    sid    = "AllowOIDCToAssumeRoles"
    effect = "Allow"
    resources = [
      format("arn:aws:iam::%s:role/github-actions", data.aws_caller_identity.current.id),
      format("arn:aws:iam::%s:role/member-delegation-%s", local.environment_management.account_ids[format("core-vpc-%s", local.environment)], local.vpc_name),
      format("arn:aws:iam::%s:role/modify-dns-records", local.environment_management.account_ids["core-network-services-production"])
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [data.aws_organizations_organization.root_account.id]
    }
  }
}