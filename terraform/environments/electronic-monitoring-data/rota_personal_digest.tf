# ------------------------------------------------------------------------------
# Personal rota digest configuration
# ------------------------------------------------------------------------------

locals {
  live_feed_pagerduty_to_slack = {
    PEYIF4Q = "U0680GPDM2S"
    PSYDXO9 = "U03U6CVFF4Z"
    PLV2QS6 = "U09EH99R7AT"
    PREPU2L = "U0851BJQCSW"
  }
}

module "rota_personal_digest_slack" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name = "rota-personal-digest-slack-${local.environment_shorthand}"

  description = "Slack bot credentials for the personal rota digest"

  recovery_window_in_days = 7

  ignore_secret_changes = true
  secret_string         = jsonencode({})

  tags = local.tags
}

# ------------------------------------------------------------------------------
# Production weekday schedule - 09:05 Europe/London
# ------------------------------------------------------------------------------

resource "aws_iam_role" "rota_personal_digest_scheduler" {
  count = local.is-production ? 1 : 0

  name = "rota_personal_digest_scheduler_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "scheduler.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "rota_personal_digest_scheduler_invoke" {
  count = local.is-production ? 1 : 0

  name = "rota_personal_digest_scheduler_invoke_policy"
  role = aws_iam_role.rota_personal_digest_scheduler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = [module.rota_personal_digest.lambda_function_arn]
      }
    ]
  })
}

resource "aws_scheduler_schedule" "rota_personal_digest" {
  count = local.is-production ? 1 : 0

  name        = "rota_personal_digest_0905"
  description = "Runs the personal rota digest at 09:05 on weekdays"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(5 9 ? * MON-FRI *)"
  schedule_expression_timezone = "Europe/London"

  target {
    arn      = module.rota_personal_digest.lambda_function_arn
    role_arn = aws_iam_role.rota_personal_digest_scheduler[0].arn
  }
}