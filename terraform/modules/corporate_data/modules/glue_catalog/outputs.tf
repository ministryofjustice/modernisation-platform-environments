output "table_name" {
  description = "Name of the created Glue table"
  value       = aws_glue_catalog_table.this.name
}

output "table_arn" {
  description = "ARN of the created Glue table"
  value       = aws_glue_catalog_table.this.arn
}