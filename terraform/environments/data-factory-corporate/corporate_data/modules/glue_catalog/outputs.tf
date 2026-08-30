output "glue_database_name" {
  description = "Name of the Glue database"
  value       = aws_glue_catalog_database.corporate_glue_database.name
}


