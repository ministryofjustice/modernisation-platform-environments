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

output "metadata_generator_lambda_arn" {
  value = module.metadata_generator.lambda_function_arn
  description = "The ARN for the metadata_generator AWS Lambda function"
}

output "validation_lambda_arn" {
  value = module.validation_lambda_function.lambda_function_arn
  description = "The ARN for the validation AWS Lambda function"
}

