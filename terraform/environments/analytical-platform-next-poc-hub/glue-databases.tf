# This registers the Glue Catalog Database that is shared via RAM
resource "aws_glue_catalog_database" "producer_resource_link" {
  name = "${local.producer_account_id}_${local.producer_database}"

  target_database {
    catalog_id    = local.producer_account_id
    database_name = local.producer_database
    region        = data.aws_region.current.name
  }

  lifecycle {
    ignore_changes = [description]
  }
}
