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


# ------------------------------------------------------------------------------
# Glue table names
# ------------------------------------------------------------------------------
# This outputs the names of all Glue tables created by the Cloud Posse module.
#
# Because the table module uses:
#
#   for_each = var.tables
#
# Terraform creates multiple module instances, one per table.
#
# That means we cannot just write:
#
#   module.corporate_glue_table.name
#
# Instead, we loop through all module instances:
#
#   for table_key, table_module in module.corporate_glue_table
#
# table_key is the table name from var.tables.
# table_module is the Cloud Posse module instance for that table.
#
# The result will look something like:
#
# {
#   table_one = "table_one"
#   table_two = "table_two"
# }
# ------------------------------------------------------------------------------

output "glue_table_names" {
  description = "Names of the Glue tables"

  value = {
    for table_key, table_module in module.corporate_glue_table :
    table_key => table_module.name
  }
}


# ------------------------------------------------------------------------------
# Glue table ARNs
# ------------------------------------------------------------------------------
# This outputs the ARN for each Glue table created by the Cloud Posse module.
#
# ARN means Amazon Resource Name.
# It is the full AWS identifier for the resource.
#
# This is useful if another Terraform module, IAM policy, or Lake Formation
# permission needs to refer to the Glue tables.
#
# The result will look something like:
#
# {
#   table_one = "arn:aws:glue:eu-west-2:123456789012:table/corporate_database/table_one"
#   table_two = "arn:aws:glue:eu-west-2:123456789012:table/corporate_database/table_two"
# }
#
# Cloud Posse's glue-catalog-table module exposes an arn output, so this is valid
# for the module version we have been using.
# ------------------------------------------------------------------------------

output "glue_table_arns" {
  description = "ARNs of the Glue tables"

  value = {
    for table_key, table_module in module.corporate_glue_table :
    table_key => table_module.arn
  }
}