resource "aws_ssm_document" "create_backup_snapshots" {
  name            = "CCMS-Create-Backup-Snapshots"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ssm/ccms-ssm-document-create-backup-snapshots.yaml")
}

resource "aws_ssm_document" "oracle_lms_cpuq" {
  name            = "CCMS-Oracle-lms-cpuq"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ssm/ccms-ssm-document-oracle-lms-cpuq.yaml")
}

resource "aws_ssm_document" "service_actions" {
  name            = "CCMS-Service-Actions"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ssm/ccms-ssm-document-service-actions.yaml")
}

resource "aws_ssm_document" "system_update" {
  name            = "CCMS-System-Update"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ssm/ccms-ssm-document-system-update.yaml")
}