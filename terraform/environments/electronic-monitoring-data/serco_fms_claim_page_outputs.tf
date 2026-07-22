output "serco_fms_claim_page_function_url" {
  description = "Function URL for the Serco FMS claim-page Lambda"
  value       = aws_lambda_function_url.serco_fms_claim_page.function_url
}