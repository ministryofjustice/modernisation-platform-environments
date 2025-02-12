output "data_filter_id" {
  value = aws_lakeformation_data_cells_filter.data_filter[*].id
}
