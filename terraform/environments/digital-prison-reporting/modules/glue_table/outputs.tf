output "table_name" {
  value = join("", aws_glue_catalog_table.glue_catalog_table[*].name)
}
