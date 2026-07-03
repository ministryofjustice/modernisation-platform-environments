output "secret_arn" {
  description = "Secrets Manager secret ARN for the supplier IAM user keys"
  value       = module.secrets_manager.secret_arn
}

output "iam_user_name" {
  description = "Supplier IAM user name"
  value       = aws_iam_user.supplier.name
}