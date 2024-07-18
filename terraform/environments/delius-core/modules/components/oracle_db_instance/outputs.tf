output "oracle_db_instance" {
  value = module.instance.aws_instance
}

output "oracle_db_server_name" {
  value = module.instance.aws_instance.tags.server-name
}