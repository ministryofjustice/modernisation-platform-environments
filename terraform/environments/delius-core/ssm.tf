##########################
# account ssm parameters #
##########################


resource "aws_ssm_parameter" "hmpps_bot_priv_key" {
  name  = "/github/hmpps_bot_priv_key"
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

resource "aws_ssm_parameter" "hmpps_bot_installation_id" {
  name  = "/github/hmpps_bot_installation_id"
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

resource "aws_ssm_parameter" "hmpps_bot_app_id" {
  name  = "/github/hmpps_bot_app_id"
  type  = "SecureString"
  value = "INITIAL_VALUE_OVERRIDDEN"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
  tags = local.tags
}

resource "aws_ssm_parameter" "account_ids" {
  name        = "account_ids"
  description = "Selected modernisation platform AWS account IDs for use by ansible"
  type        = "SecureString"
  key_id      = data.aws_kms_key.general_shared.arn
  value = jsonencode({
    for key, value in local.environment_management.account_ids :
    key => value if contains(["hmpps-oem-${local.environment}"], key)
  })

  tags = merge(local.tags, {
    Name = "account_ids"
  })
}
