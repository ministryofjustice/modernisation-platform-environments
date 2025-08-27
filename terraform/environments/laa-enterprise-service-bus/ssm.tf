resource "aws_ssm_parameter" "ccms_provider_load_timestamp" {
  name        = "/HUB2.0/ccms_processed_timestamp"
  description = "timestamp value of last successful process"
  type        = "SecureString"
  value       = "test-value"
  key_id      = "alias/aws/ssm"

  lifecycle {
    ignore_changes = [value]
  }
}