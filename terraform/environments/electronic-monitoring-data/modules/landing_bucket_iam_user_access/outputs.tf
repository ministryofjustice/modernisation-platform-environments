output "secret_arn" {
  value = module.secrets_manager.secret_arn
}

output "secret_id" {
  value = module.secrets_manager.secret_id
}

output "iam_key_arn" {
  value = aws_iam_access_key.supplier.arn
}
