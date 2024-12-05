##
# Output variables here
##

output "oracle_db_server_names" {
  value = module.environment_dev[0].oracle_db_server_names.primarydb
}

output "oracle_db_instance_scheduling" {
  value = module.environment_dev[0].oracle_db_instance_scheduling
}