# ------------------------------------------------------------------------
# Lake Formation - admin permissions
# https://user-guide.modernisation-platform.service.justice.gov.uk/runbooks/adding-admin-data-lake-formation-permissions.html
# ------------------------------------------------------------------------

locals {
  admin_roles = local.is-development ? "sandbox" : "data-eng"
}

data "aws_iam_role" "github_actions_role" {
  name = "github-actions"
}

data "aws_iam_roles" "mod_plat_roles" {
  name_regex  = "AWSReservedSSO_modernisation-platform-${local.admin_roles}_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}


resource "aws_lakeformation_data_lake_settings" "settings" {
  admins = flatten(
    [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.mod_plat_roles.names)}",
      data.aws_iam_role.github_actions_role.arn,
      data.aws_iam_session_context.current.issuer_arn,
      [for share in local.analytical_platform_share : aws_iam_role.analytical_platform_share_role[share.target_account_name].arn],
    ]
  )
  parameters = {
    "CROSS_ACCOUNT_VERSION" = "4"
  }
}

resource "aws_lakeformation_lf_tag" "domain_tag" {
  key    = "domain"
  values = ["prisons", "probation", "electronic-monitoring"]
}

resource "aws_lakeformation_lf_tag" "sensitive_tag" {
  key    = "sensitive"
  values = ["true", "false"]
}

resource "aws_lakeformation_permissions" "domain_grant" {
  principal   = aws_iam_role.dataapi_cross_role.arn
  permissions = ["DESCRIBE", "ASSOCIATE", "GRANT_WITH_LF_TAG_EXPRESSION"]

  lf_tag {
    key    = aws_lakeformation_lf_tag.domain_tag.key
    values = aws_lakeformation_lf_tag.domain_tag.values
  }

}

resource "aws_lakeformation_permissions" "sensitive_grant" {
  principal   = aws_iam_role.dataapi_cross_role.arn
  permissions = ["DESCRIBE", "ASSOCIATE", "GRANT_WITH_LF_TAG_EXPRESSION"]

  lf_tag {
    key    = aws_lakeformation_lf_tag.sensitive_tag.key
    values = aws_lakeformation_lf_tag.sensitive_tag.values
  }

}
