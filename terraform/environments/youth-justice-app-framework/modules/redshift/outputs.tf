output "security_group_id" {
  description = "The ID of the Security Groups that is used to controll access to Redshift."
  value       = module.redshift_sg.security_group_id
}

output "address" {
  description = "The DNS address for this Redshift serverless instance."
  value       = aws_redshiftserverless_workgroup.default.endpoint[0].address
}

output "port" {
  description = "The port that this Redshift servless instance listens on."
  value       = aws_redshiftserverless_workgroup.default.endpoint[0].port
}