resource "aws_ssm_document" "ebs_apps_service_start" {
  name            = "EBS-Apps-Service-Start"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ccms-ssm-document-ebs-apps-service-start.yaml")
}

resource "aws_ssm_document" "ebs_apps_service_status" {
  name            = "EBS-Apps-Service-Status"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ccms-ssm-document-ebs-apps-service-status.yaml")
}

resource "aws_ssm_document" "ebs_apps_service_stop" {
  name            = "EBS-Apps-Service-Stop"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ccms-ssm-document-ebs-apps-service-stop.yaml")
}