##
# Output variables here
##

output "acm_domains" {
  value = aws_acm_certificate.external
}

output "oracle_db_server_names" {
  value = local.oracle_db_server_names
}

output "dms_s3_bucket_name" {
  value = local.dms_s3_bucket_name
}

output "dms_s3_bucket_info" {
  value = local.dms_s3_bucket_info
}
