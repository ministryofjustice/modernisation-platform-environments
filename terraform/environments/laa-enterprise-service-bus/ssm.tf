resource "aws_ssm_parameter" "ccms_provider_load_timestamp" {
  name        = "/${local.application_name_short}/ccms-load-timestamp-${local.environment}"
  description = "timestamp value of last successful process of CCMS lambda"
  type        = "SecureString"
  value       = "test-value"
  key_id      = "alias/aws/ssm"

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-ccms-provider-load-timestamp"
    }
  )
}

resource "aws_ssm_parameter" "cclf_provider_load_timestamp" {
  name        = "/${local.application_name_short}/cclf-load-timestamp-${local.environment}"
  description = "timestamp value of last successful process CCLF lambda"
  type        = "SecureString"
  value       = "test-value"
  key_id      = "alias/aws/ssm"

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-cclf-provider-load-timestamp"
    }
  )
}

resource "aws_ssm_parameter" "maat_provider_load_timestamp" {
  name        = "/${local.application_name_short}/maat-load-timestamp-${local.environment}"
  description = "timestamp value of last successful process MAAT lambda"
  type        = "SecureString"
  value       = "test-value"
  key_id      = "alias/aws/ssm"

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-maat-provider-load-timestamp"
    }
  )
}

resource "aws_ssm_parameter" "ccr_provider_load_timestamp" {
  name        = "/${local.application_name_short}/ccr-load-timestamp-${local.environment}"
  description = "timestamp value of last successful process of CCR load lambda"
  type        = "SecureString"
  value       = "test-value"
  key_id      = "alias/aws/ssm"

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-ccr-provider-load-timestamp"
    }
  )
}