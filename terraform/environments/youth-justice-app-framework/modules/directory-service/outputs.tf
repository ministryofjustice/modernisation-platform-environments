output "ds_managed_ad_id" {
  value = aws_directory_service_directory.ds_managed_ad.id
}

output "ds_managed_ad_ips" {
  value = aws_directory_service_directory.ds_managed_ad.dns_ip_addresses
}

output "managed_ad_password_secret_id" {
  value = aws_secretsmanager_secret.mad_admin_secret.id
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.ds.name
}
