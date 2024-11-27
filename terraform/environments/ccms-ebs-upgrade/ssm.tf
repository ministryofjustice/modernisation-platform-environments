resource "aws_ssm_document" "create_backup_snapshots" {
  name            = "CCMS-Create-Backup-Snapshots"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ssm-create-backup-snapshots.yaml")
}

resource "aws_ssm_document" "oracle_lms_cpuq" {
  name            = "CCMS-Oracle-lms-cpuq"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ssm-oracle-lms-cpuq.yaml")
}

resource "aws_ssm_document" "system_update" {
  name            = "CCMS-System-Update"
  document_type   = "Command"
  document_format = "YAML"

  content = file("ssm-document-system-update.yaml")
}