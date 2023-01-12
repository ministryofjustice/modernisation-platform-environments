output "bastion_security_group" {
  value       = module.bastion_linux.bastion_security_group
  description = "Security group of bastion"
}

output "bastion_launch_template" {
  description = "Launch template of bastion"
  value       = module.bastion_linux.bastion_launch_template
}

output "bastion_s3_bucket" {
  description = "S3 bucket of bastion"
  value       = module.bastion_linux.bastion_s3_bucket
}