output "data_filter_id" {
  value = values(aws_lakeformation_data_cells_filter.data_filter)[*].table_data[0].name
}
