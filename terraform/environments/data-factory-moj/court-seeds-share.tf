locals {
  court_seeds_database_name = "court_seeds"

  court_seeds_governance_account_id = local.environment_management.account_ids["data-platform-governance-${local.environment_configuration.data_lake_environment}"]
}

resource "aws_ram_resource_share" "court_seeds" {
  name                      = local.court_seeds_database_name
  allow_external_principals = false

  tags = merge(
    local.tags,
    {
      "justice-data-lake-database" = local.court_seeds_database_name
    }
  )
}

resource "aws_ram_principal_association" "court_seeds_governance" {
  principal          = local.court_seeds_governance_account_id
  resource_share_arn = aws_ram_resource_share.court_seeds.arn
}

resource "aws_ram_resource_association" "court_seeds" {
  resource_arn = "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:database/${local.court_seeds_database_name}"

  resource_share_arn = aws_ram_resource_share.court_seeds.arn
}

resource "aws_lakeformation_permissions" "court_seeds_database" {
  principal                     = local.court_seeds_governance_account_id
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]

  database {
    name = local.court_seeds_database_name
  }
}

resource "aws_lakeformation_permissions" "court_seeds_tables" {
  principal                     = local.court_seeds_governance_account_id
  permissions                   = ["DESCRIBE", "SELECT"]
  permissions_with_grant_option = ["DESCRIBE", "SELECT"]

  table {
    database_name = local.court_seeds_database_name
    wildcard      = true
  }
}
