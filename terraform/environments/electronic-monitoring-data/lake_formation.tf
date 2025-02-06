# ------------------------------------------------------------------------
# Lake Formation - admin permissions
# https://user-guide.modernisation-platform.service.justice.gov.uk/runbooks/adding-admin-data-lake-formation-permissions.html
# ------------------------------------------------------------------------

data "aws_iam_role" "github_actions_role" {
  name = "github-actions"
}

data "aws_iam_roles" "modernisation_platform_sandbox_role" {
  name_regex  = "AWSReservedSSO_modernisation-platform-sandbox_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

resource "aws_lakeformation_data_lake_settings" "emds_development" {
  count = local.is-development ? 1 : 0

  admins = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.modernisation_platform_sandbox_role.names)}",
    data.aws_iam_role.github_actions_role.arn
  ]
}
