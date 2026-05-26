resource "aws_ssm_document" "trend_av_installer" {
  name            = "trend-av-installer"
  document_type   = "Command"
  document_format = "YAML"

  content = file("${path.module}/ssm-document.yaml")

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [content]
  }
}


resource "aws_ssm_association" "run_once_on_launch" {
  name             = aws_ssm_document.trend_av_installer.name
  association_name = "Trend_av_installer"

  targets {
    key    = "tag:install-trend-av"
    values = ["true"]
  }

  compliance_severity = "HIGH"
}