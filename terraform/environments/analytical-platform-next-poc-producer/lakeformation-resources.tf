resource "aws_glue_catalog_database" "database_resource_links" {
  name = "example_from_governance"

  target_database {
    catalog_id    = local.hub_account_id
    database_name = "example_database"
    region        = "eu-west-2"
  }
}
