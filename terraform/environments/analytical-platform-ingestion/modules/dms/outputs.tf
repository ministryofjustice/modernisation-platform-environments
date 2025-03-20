output "dms_role_arn" {
  value = aws_iam_role.dms.arn
  description = "The ARN for the AWS role created for the DMS target endpoint"
  sensitive = true
}

output "dms_source_role_arn" {
  value = aws_iam_role.dms_source.arn
  description = "The ARN for the AWS role created for the DMS source endpoint"
  sensitive = true
}
