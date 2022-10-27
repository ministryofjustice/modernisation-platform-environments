locals {
}

resource "aws_glue_catalog_database" "glue_database" {
  count = var.create_db ? 1 : 0

  name = var.name

  description  = var.description
  catalog_id   = var.catalog
  location_uri = var.location_uri
  parameters   = var.params

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = []
}