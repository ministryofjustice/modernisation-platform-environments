# DataSync outputs
output "datasync_task_arn" {
  description = "ARN of the DataSync task for S3 to FSX sync"
  value       = var.datasync_config != null ? aws_datasync_task.dfi_s3_to_fsx[0].arn : null
}

output "datasync_fsx_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing FSX credentials"
  value       = var.datasync_config != null ? data.aws_secretsmanager_secret.datasync_ad_admin_password[0].arn : null
}

output "fsx_dns_name" {
  description = "DNS name of the FSX Windows file system"
  value       = aws_fsx_windows_file_system.mis_share.dns_name
}

output "fsx_share_path" {
  description = "Full UNC path to the FSX share for DFI reports"
  value       = "\\\\${aws_fsx_windows_file_system.mis_share.dns_name}\\share\\dfiinterventions\\dfi"
}

# Load Balancer outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.lb_config != null ? aws_lb.mis[0].dns_name : null
}

output "dfi_url" {
  description = "Full HTTPS URL for the DFI service"
  value       = var.lb_config != null && var.dfi_config != null && var.dfi_config.instance_count > 0 ? "https://${local.dfi_fqdn}${local.dfi_health_check_path}" : null
}

output "dis_url" {
  description = "Full HTTPS URL for the DIS service"
  value       = var.lb_config != null && var.dis_config != null && var.dis_config.instance_count > 0 ? "https://${local.dis_fqdn}${local.dis_health_check_path}" : null
}

output "dfi_fqdn" {
  description = "Fully qualified domain name for DFI service"
  value       = var.lb_config != null && var.dfi_config != null && var.dfi_config.instance_count > 0 ? local.dfi_fqdn : null
}

output "dis_fqdn" {
  description = "Fully qualified domain name for DIS service"
  value       = var.lb_config != null && var.dis_config != null && var.dis_config.instance_count > 0 ? local.dis_fqdn : null
}
