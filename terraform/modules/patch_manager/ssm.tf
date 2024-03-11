resource "aws_ssm_document" "extract-upload-patches" {
  count           = var.environment == "development" ? 1 : 0
  name            = "extract-upload-patches"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("${path.module}/ExtractAndUploadPatches.yaml")

}
