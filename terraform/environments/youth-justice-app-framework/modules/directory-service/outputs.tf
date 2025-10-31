output "ds_managed_ad_id" {
  value = aws_directory_service_directory.ds_managed_ad.id
}

output "managed_ad_password_secret_id" {
  value = aws_secretsmanager_secret.mad_admin_secret.id
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.ds.name
}

output "directory_service_sg_id" {
  value = aws_directory_service_directory.ds_managed_ad.security_group_id
}

output "management_server_sg_id" {
  value = aws_security_group.mgmt_instance_sg.id
}

output "dns_ip_addresses" {
  value = data.aws_directory_service_directory.built_ad.dns_ip_addresses
}