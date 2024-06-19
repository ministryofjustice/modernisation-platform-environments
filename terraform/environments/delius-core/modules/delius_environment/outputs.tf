##
# Output variables here
##

output "acm_domains" {
  value = aws_acm_certificate.external
}

output "oracle_db_server_names" {
  value = {
     primarydb = module.oracle_db_primary[0].oracle_db_server_name,
     standbydb1 = try(module.oracle_db_standby[0].oracle_db_server_name,"none"),
     standbydb2 = try(module.oracle_db_standby[1].oracle_db_server_name,"none")
  }
}