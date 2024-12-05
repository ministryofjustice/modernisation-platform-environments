##
# Output variables here
##

output "acm_domains" {
  value = aws_acm_certificate.external
}

output "oracle_db_server_names" {
  value = local.oracle_db_server_names
}

output "oracle_db_instance_scheduling" {
  value = module.oracle_db_primary[0].oracle_db_instance_scheduling
}