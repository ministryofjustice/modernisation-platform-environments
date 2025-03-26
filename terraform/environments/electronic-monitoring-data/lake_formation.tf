# ------------------------------------------------------------------------
# Lake Formation - admin permissions
# https://user-guide.modernisation-platform.service.justice.gov.uk/runbooks/adding-admin-data-lake-formation-permissions.html
# ------------------------------------------------------------------------
locals {
  dbt_principals = flatten(
    [
      one(data.aws_iam_roles.data_engineering_roles.arns),
      aws_iame_role.dataapi_cross_role.arn
    ]
  )
}


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


resource "aws_glue_catalog_database" "dbt_test__audit" {
  name = "dbt_test__audit${local.dbt_suffix}"
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      description,
      location_uri,
      parameters,
      target_database
    ]
  }
}

resource "aws_glue_catalog_database" "audit_test_database" {
  name = "testing${local.dbt_suffix}"
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      description,
      location_uri,
      parameters,
      target_database
    ]
  }
}

resource "aws_lakeformation_permissions" "admin_permissions_dbt_test_tables" {
  for_each    = toset(local.dbt_principals)
  principal   = each.key
  permissions = ["ALL"]

  table {
    database_name = aws_glue_catalog_database.dbt_test__audit.name
    wildcard      = true
  }
}

resource "aws_lakeformation_permissions" "admin_permissions_dbt_test_db" {
  for_each    = toset(local.dbt_principals)
  principal   = each.key
  permissions = ["ALL"]

  database {
    name = aws_glue_catalog_database.dbt_test__audit.name
  }
}

resource "aws_lakeformation_permissions" "admin_permissions_dbt_testing_audit" {
  for_each    = toset(local.dbt_principals)
  principal   = each.key
  permissions = ["ALL"]
  table {
    database_name = aws_glue_catalog_database.audit_test_database.name
    wildcard      = true
  }
}

resource "aws_lakeformation_permissions" "admin_permissions_dbt_testing_audit_db" {
  for_each    = toset(local.dbt_principals)
  principal   = each.key
  permissions = ["ALL"]

  database {
    name = aws_glue_catalog_database.audit_test_database.name
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
