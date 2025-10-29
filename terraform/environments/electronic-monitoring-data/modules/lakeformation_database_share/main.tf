locals {
  dbs_to_create = var.db_exists ? toset([]) : toset(var.dbs_to_grant)
  grant_dbs     = var.db_exists ? { for db in var.dbs_to_grant : db => db } : { for k, v in aws_glue_catalog_database.cadt_databases : k => v.name }
}
data "aws_caller_identity" "current" {}

resource "aws_lakeformation_permissions" "s3_bucket_permissions" {
  principal = var.role_arn

  permissions = ["DATA_LOCATION_ACCESS"]
  data_location {
    arn = var.data_bucket_lf_resource
  }
}

resource "aws_lakeformation_permissions" "grant_cadt_databases_existing" {
  for_each = var.db_exists ? { for db in var.dbs_to_grant : db => db } : {}
  principal                     = var.role_arn
  permissions                   = ["ALL"]
  permissions_with_grant_option = ["ALL"]
  database {
    name = each.value
  }
}

resource "aws_lakeformation_permissions" "grant_cadt_databases_new" {
  for_each = var.db_exists ? {} : { for db in aws_glue_catalog_database.cadt_databases : db.name => db.name}
  principal                     = var.role_arn
  permissions                   = ["ALL"]
  permissions_with_grant_option = ["ALL"]
  database {
    name = each.value
  }
}

resource "aws_lakeformation_permissions" "grant_cadt_tables_existing" {
  for_each = var.db_exists ? { for db in var.dbs_to_grant : db => db } : {}
  principal                     = var.role_arn
  permissions                   = ["ALL"]
  permissions_with_grant_option = ["ALL"]

  table {
    database_name = each.value
    wildcard      = true
  }
}

resource "aws_lakeformation_permissions" "grant_cadt_tables_new" {
  for_each = var.db_exists ? {} :  { for db in aws_glue_catalog_database.cadt_databases : db.name => db.name}
  principal = var.role_arn
  permissions = ["ALL"]
  permissions_with_grant_option = ["ALL"]

  table {
    database_name = each.value
    wildcard      = true
  }

  depends_on = [aws_glue_catalog_database.cadt_databases]
}

resource "aws_lakeformation_permissions" "s3_bucket_permissions_de" {
  principal = var.de_role_arn

  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = var.data_bucket_lf_resource
  }
}


resource "aws_lakeformation_permissions" "grant_cadt_databases_de_existing" {
  for_each = var.db_exists ? { for db in var.dbs_to_grant : db => db } : {}
  principal                     = var.de_role_arn
  permissions                   = ["ALL"]
  permissions_with_grant_option = ["ALL"]
  database {
    name = each.value
  }
}

resource "aws_lakeformation_permissions" "grant_cadt_databases_de_new" {
  for_each = var.db_exists ? {} : { for db in aws_glue_catalog_database.cadt_databases : db.name => db.name}
  principal                     = var.de_role_arn
  permissions                   = ["ALL"]
  permissions_with_grant_option = ["ALL"]
  database {
    name = each.value
  }
}

resource "aws_lakeformation_permissions" "grant_cadt_tables_de_existing" {
  for_each = var.db_exists ? { for db in var.dbs_to_grant : db => db } : {}
  principal                     = var.de_role_arn
  permissions                   = ["ALL"]
  permissions_with_grant_option = ["ALL"]

  table {
    database_name = each.value
    wildcard      = true
  }
}

resource "aws_lakeformation_permissions" "grant_cadt_tables_de_new" {
  for_each = var.db_exists ? {} :  { for db in aws_glue_catalog_database.cadt_databases : db.name => db.name}
  principal                     = var.de_role_arn
  permissions                   = ["ALL"]
  permissions_with_grant_option = ["ALL"]

  table {
    database_name = each.value
    wildcard      = true
  }

  depends_on = [aws_glue_catalog_database.cadt_databases]
}

resource "aws_glue_catalog_database" "cadt_databases" {
  for_each = local.dbs_to_create

  name = each.value
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
