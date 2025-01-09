data "aws_caller_identity" "current" {}

resource "aws_lakeformation_permissions" "s3_bucket_permissions" {
  principal = var.role_arn

  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = var.data_bucket_lf_resource
  }
}


resource "aws_lakeformation_permissions" "grant_cadt_databases" {
  for_each    = aws_glue_catalog_database.cadt_databases[*].id
  principal   = var.role_arn
  permissions = ["ALL"]
  database {
    name = each.value
  }
}

resource "aws_lakeformation_permissions" "grant_cadt_tables" {
  for_each    = aws_glue_catalog_database.cadt_databases[*].id
  principal   = var.role_arn
  permissions = ["ALL"]
  table {
    database_name = each.value
    wildcard      = true
  }
}

resource "aws_glue_catalog_database" "cadt_databases" {
  for_each = var.dbs_to_grant

  name = each.value
}
