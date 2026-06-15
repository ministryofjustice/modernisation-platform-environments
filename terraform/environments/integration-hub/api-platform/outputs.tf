output "transfer_ticket_api_endpoint" {
  description = "HTTP API endpoint for issuing managed file transfer upload tickets"
  value       = aws_apigatewayv2_api.upload_ticket.api_endpoint
}

output "transfer_clients_table_name" {
  description = "DynamoDB table containing upload client configuration"
  value       = module.dynamodb_transfer_clients.dynamodb_table_id
}
