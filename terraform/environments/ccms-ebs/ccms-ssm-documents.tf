resource "aws_ssm_document" "service_actions" {
  name            = "ServiceActions"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ccms-ssm-document-service-actions.yaml")
}