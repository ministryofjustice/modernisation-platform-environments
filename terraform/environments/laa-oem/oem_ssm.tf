resource "aws_ssm_document" "oracle_lms_cpuq" {
  name            = "Oracle-lms-cpuq"
  document_type   = "Command"
  document_format = "YAML"

  content = file("oem_ssm_oracle_lms_cpuq.yaml")
}