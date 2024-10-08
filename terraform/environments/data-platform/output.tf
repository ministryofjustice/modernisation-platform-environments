
output "docs_endpoint" {
  value = join("", [aws_api_gateway_deployment.deployment.invoke_url, aws_api_gateway_stage.default_stage.stage_name, "/docs/"])
}

output "presigned_url_endpoint" {
  value = join("", [aws_api_gateway_deployment.deployment.invoke_url, aws_api_gateway_stage.default_stage.stage_name, "/presigned_url/"])
}
