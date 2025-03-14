output "sagemaker_model_name" {
  value = aws_sagemaker_model.model.name
}

output "sagemaker_endpoint_arn" {
  value = aws_sagemaker_endpoint.endpoint.arn
}

output "sagemaker_execution_role_arn" {
  value = module.sagemaker_execution_iam_role.iam_role_arn
}
