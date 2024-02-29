resource "aws_ssm_document" "test" {
  name            = "TestSSMdocument"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ccms-ssm-document-test.yaml")
}