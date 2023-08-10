
output "docs_endpoint" {
  value = join("", [aws_api_gateway_deployment.deployment.invoke_url, "aws_api_gateway_stage.${local.environment}.stage_name", "/docs/"])
}

output "get_glue_metadata_endpoint" {
  value = join("", [aws_api_gateway_deployment.deployment.invoke_url, "aws_api_gateway_stage.${local.environment}.stage_name", "/get_glue_metadata/"])
}

output "presigned_url_endpoint" {
  value = join("", [aws_api_gateway_deployment.deployment.invoke_url, "aws_api_gateway_stage.${local.environment}.stage_name", "/presigned_url/"])
}