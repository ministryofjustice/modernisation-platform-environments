resource "aws_ssm_document" "create_backup_snapshots" {
  name            = "CCMS-Create-Backup-Snapshots"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ccms-ssm-create-backup-snapshots.yaml")
}

resource "aws_ssm_document" "service_actions" {
  name            = "CCMS-Service-Actions"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ccms-ssm-document-service-actions.yaml")
}

resource "aws_ssm_document" "oracle_lms_cpuq" {
  name            = "Oracle-lms-cpuq"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ccms-ssm-document-oracle-lms-cpuq.yaml")
}