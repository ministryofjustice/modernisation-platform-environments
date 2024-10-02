output "secret" {
  value = aws_secretsmanager_secret.supplier
}

output "iam_key_arn" {
  value = aws_iam_access_key.supplier.arn
}
