output "oracle_db_server_names" {
  value = module.environment_dev[0].oracle_db_server_names
}


output "where_am_i" {
    value = local.environment
}