output "redshift_security_group_id" {
  description = "The ID of the Security Groups that is used to controll access to Redshift."
  value       = module.redshift_sg.security_group_id
}