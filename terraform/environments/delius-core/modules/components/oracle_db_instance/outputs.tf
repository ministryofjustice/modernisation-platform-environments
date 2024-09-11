output "oracle_db_server_name" {
  value = module.instance.aws_instance.tags.server-name
}