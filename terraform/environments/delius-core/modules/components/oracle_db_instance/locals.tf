locals {
  instance_name_index = var.db_type == "primary" ? var.db_count_index : var.db_count_index + 1
  database_tag        = var.db_type == "primary" ? "${split("_", var.server_type_tag)[0]}_${var.db_type}db" : "${split("_", var.server_type_tag)[0]}_${var.db_type}db${var.db_count_index}"
}