output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.airflow_role.name
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.airflow_role.arn
}

output "role_unique_id" {
  description = "Stable and unique string identifying the IAM role"
  value       = aws_iam_role.airflow_role.unique_id
}