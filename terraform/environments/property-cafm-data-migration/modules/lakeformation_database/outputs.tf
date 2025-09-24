output "database_name" {
  description = "The name of the lakeformation database"
  value       = aws_glue_catalog_database.lakeformation_database.name
}
