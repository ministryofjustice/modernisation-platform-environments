# Adapted from ministryofjustice/terraform-aws-moj-data-factory-modules
# modules/data-factory-glue-database at 75a5fd1ccb6c1858508b98651030cc4c919b9d03.

resource "aws_glue_catalog_database" "data_factory_database" {
  name         = var.database_name
  location_uri = "s3://${var.storage.bucket_name}/${trim(var.storage.prefix, "/")}"
  description  = "Glue catalog database for ${var.database_name}"
  tags = merge(var.tags, {
    "Name" = "data-factory-${var.database_name}-glue-database"
  })
}