output "grant_iam_role_arn" {
  description = "ARN for Grant Location IAM Role"
  value       = aws_iam_role.s3.arn
}
