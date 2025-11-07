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

output "quicksight_secret_arn" {
  description = "The secret created to hold the quicksight credentials."
  value       = aws_secretsmanager_secret.yjb_publish.arn
}

output "returns_secret_arn" {
  description = "The secret created to hold the returns credentials."
  value       = aws_secretsmanager_secret.returns.arn
}
