# ------------------------------------------------------------------------------
# Rota channel notifier configuration
# ------------------------------------------------------------------------------

locals {
  em_rota_schedule_mode = "shift"

  em_rota_schedules = {
    legacy = {
      id      = "P3MCA8L"
      version = "v2"
    }

    shift = {
      id      = "P4M9I3U"
      version = "v3"
    }
  }

  em_active_rota_schedule = local.em_rota_schedules[
    local.em_rota_schedule_mode
  ]

  rota_channel_notifier_slack_channels = {
    dev     = "C0A51K7L2QG"
    test    = "C09C3P43UNP"
    preprod = "C09EVH89M35"
    prod    = "C069RF589V4"
  }
}

module "rota_channel_notifier_slack" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.2.0"

  name = "rota-channel-notifier-slack-${local.environment_shorthand}"

  description = "Slack bot credentials for the rota channel notifier"

  recovery_window_in_days = 7

  ignore_secret_changes = true
  secret_string         = jsonencode({})

  tags = local.tags
}
