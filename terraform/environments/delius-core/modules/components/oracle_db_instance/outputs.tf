output "oracle_db_server_name" {
  value = module.instance.aws_instance.tags.server-name
}

output "oracle_db_instance_scheduling" {
  value = try(module.instance.aws_instance.tags.instance-scheduling, "default")
}