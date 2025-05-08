# Modernisation platform - adding Admin Data Lake permissions
# https://user-guide.modernisation-platform.service.justice.gov.uk/runbooks/adding-admin-data-lake-formation-permissions.html#configuration-overview

data "aws_iam_role" "github_actions_role" {
  name = "github-actions"
}

data "aws_iam_roles" "modernisation_platform_sandbox_role" {
  name_regex  = "AWSReservedSSO_modernisation-platform-sandbox_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}


resource "aws_lakeformation_data_lake_settings" "lake_formation" {
  admins = [
    data.aws_iam_role.github_actions_role.arn,
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${data.aws_region.current.name}/${one(data.aws_iam_roles.modernisation_platform_sandbox_role.names)}"
  ]

  create_database_default_permissions {
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  create_table_default_permissions {
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }
}

resource "aws_lakeformation_lf_tag" "domain_tag" {
  key    = "domain"
  values = ["prisons", "probation", "electonic-monitoring"]
}

resource "aws_lakeformation_lf_tag" "sensitive_tag" {
  key    = "sensitive"
  values = ["true", "false", "data_linking"]
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
