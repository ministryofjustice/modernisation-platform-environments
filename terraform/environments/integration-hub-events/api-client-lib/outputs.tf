output "hello_api_url" {
  description = "Public URL of the hello API. GET <url>/<name> returns Hello <name>"
  value       = aws_apigatewayv2_stage.hello.invoke_url
}
