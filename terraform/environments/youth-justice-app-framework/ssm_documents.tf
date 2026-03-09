resource "aws_ssm_document" "trend_av_installer" {
  name            = "trend-av-installer"
  document_type   = "Command"
  document_format = "YAML"

  content = file("${path.module}/ssm-document.yaml")
}
