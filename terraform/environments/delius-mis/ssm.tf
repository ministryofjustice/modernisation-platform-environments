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