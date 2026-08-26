output "db_name" {
  value = join(",", aws_glue_catalog_database.glue_database.*.name)
}
