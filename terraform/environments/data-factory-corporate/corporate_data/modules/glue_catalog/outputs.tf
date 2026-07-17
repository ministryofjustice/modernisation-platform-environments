# ------------------------------------------------------------------------------
# Glue database name
# ------------------------------------------------------------------------------
# This outputs the name of the Glue database created in main.tf.
#
# Because the database is created using a direct Terraform resource:
#
#   resource "aws_glue_catalog_database" "corporate_glue_database"
#
# we reference it using:
#
#   aws_glue_catalog_database.corporate_glue_database.name
#
# This is useful because after Terraform runs, the output will clearly show
# which Glue database was created or used.
# ------------------------------------------------------------------------------

output "glue_database_name" {
  description = "Name of the Glue database"
  value       = aws_glue_catalog_database.corporate_glue_database.name
}


