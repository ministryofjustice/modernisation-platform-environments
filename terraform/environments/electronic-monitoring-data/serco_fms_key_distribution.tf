locals {
  serco_fms_key_distribution_enabled = false

  # placeholder value once GOV.UK Notify template is created
  serco_fms_key_distribution_notify_template_id = (
    "f547eba8-a5d4-4218-b5ff-a238bc054136"
  )

  serco_fms_key_distribution_state_prefix = "state"

  serco_fms_key_distribution_secret_specs = [
    {
      label      = "General"
      secret_arn = module.s3-fms-general-landing-bucket-iam-user.secret_arn
    },
    {
      label      = "Home Office"
      secret_arn = module.s3-fms-ho-landing-bucket-iam-user.secret_arn
    },
    {
      label      = "Specials"
      secret_arn = module.s3-fms-specials-landing-bucket-iam-user.secret_arn
    },
  ]

  serco_fms_key_distribution_feed_secret_arns = [
    for spec in local.serco_fms_key_distribution_secret_specs :
    spec.secret_arn
  ]

  serco_fms_key_distribution_config_secret_arns = [
    aws_secretsmanager_secret.govuk_notify_serco_fms_api_key.arn,
  ]

  serco_fms_key_distribution_secret_arns = concat(
    local.serco_fms_key_distribution_feed_secret_arns,
    local.serco_fms_key_distribution_config_secret_arns
  )
}

resource "aws_secretsmanager_secret" "serco_fms_password_state" {
  name        = "serco-fms-key-distribution-password-state-${local.environment_shorthand}"
  description = "Generated passwords for Serco FMS encrypted key files"

  tags = merge(
    local.tags,
    {
      purpose = "serco-fms-key-distribution"
    }
  )
}

resource "aws_secretsmanager_secret_version" "serco_fms_password_state" {
  secret_id = aws_secretsmanager_secret.serco_fms_password_state.id

  # placeholder value until the first generated password is written
  secret_string = jsonencode({
    environment = local.environment_shorthand
    period      = "PLACEHOLDER"
    password    = "PLACEHOLDER"
    created_at  = "PLACEHOLDER"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "govuk_notify_serco_fms_api_key" {
  name        = "govuk-notify-serco-fms-api-key-${local.environment_shorthand}"
  description = "GOV.UK Notify API key for Serco FMS key distribution"

  tags = merge(
    local.tags,
    {
      purpose = "serco-fms-key-distribution"
    }
  )
}

resource "aws_secretsmanager_secret_version" "govuk_notify_serco_fms_api_key" {
  secret_id = aws_secretsmanager_secret.govuk_notify_serco_fms_api_key.id

  # placeholder value once GOV.UK Notify service key is agreed
  secret_string = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_iam_role" "send_serco_fms_keys" {
  name               = "send_serco_fms_keys_lambda_role_${local.environment_shorthand}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "send_serco_fms_keys" {
  statement {
    sid    = "ReadCredentialAndConfigSecrets"
    effect = "Allow"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds",
    ]

    resources = local.serco_fms_key_distribution_secret_arns
  }

  statement {
    sid    = "WriteGeneratedPasswordStateSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:PutSecretValue",
    ]

    resources = [
      aws_secretsmanager_secret.serco_fms_password_state.arn,
    ]
  }

  statement {
    sid    = "ListDistributionState"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      module.s3-serco-fms-key-distribution-bucket.bucket.arn,
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "${local.serco_fms_key_distribution_state_prefix}/${local.environment_shorthand}",
        "${local.serco_fms_key_distribution_state_prefix}/${local.environment_shorthand}/*",
      ]
    }
  }

  statement {
    sid    = "ReadWriteDistributionState"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "${module.s3-serco-fms-key-distribution-bucket.bucket.arn}/${local.serco_fms_key_distribution_state_prefix}/${local.environment_shorthand}/*",
    ]
  }

  statement {
    sid    = "ReadDistributionAllowlist"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]

    resources = [
      "${module.s3-serco-fms-key-distribution-bucket.bucket.arn}/${local.serco_fms_key_distribution_allowlist_key}",
    ]
  }

  statement {
    sid    = "WriteEncryptedDistributionFiles"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]

    resources = [
      "${module.s3-serco-fms-key-distribution-bucket.bucket.arn}/${local.serco_fms_key_distribution_files_prefix}/${local.environment_shorthand}/*",
    ]
  }
}

resource "aws_iam_policy" "send_serco_fms_keys" {
  name   = "send_serco_fms_keys_lambda_policy_${local.environment_shorthand}"
  policy = data.aws_iam_policy_document.send_serco_fms_keys.json
}

resource "aws_iam_role_policy_attachment" "send_serco_fms_keys" {
  role       = aws_iam_role.send_serco_fms_keys.name
  policy_arn = aws_iam_policy.send_serco_fms_keys.arn
}

module "send_serco_fms_keys" {
  source                         = "./modules/lambdas"
  is_image                       = true
  function_name                  = "send_serco_fms_keys"
  role_name                      = aws_iam_role.send_serco_fms_keys.name
  role_arn                       = aws_iam_role.send_serco_fms_keys.arn
  handler                        = "send_serco_fms_keys.handler"
  memory_size                    = 512
  timeout                        = 120
  reserved_concurrent_executions = 1
  core_shared_services_id        = local.environment_management.account_ids["core-shared-services-production"]
  production_dev                 = local.is-production ? "prod" : local.is-preproduction ? "preprod" : local.is-test ? "test" : "dev"

  environment_variables = {
    SERCO_KEY_DISTRIBUTION_ENABLED = (
      tostring(local.serco_fms_key_distribution_enabled)
    )

    SERCO_KEY_DISTRIBUTION_ENCRYPTION_MODE = "password"

    ENVIRONMENT = local.environment_shorthand

    SECRET_SPEC_JSON = jsonencode(
      local.serco_fms_key_distribution_secret_specs
    )

    SERCO_PASSWORD_STATE_SECRET_ARN = (
      aws_secretsmanager_secret.serco_fms_password_state.arn
    )

    GOVUK_NOTIFY_API_KEY_SECRET_ARN = (
      aws_secretsmanager_secret.govuk_notify_serco_fms_api_key.arn
    )

    GOVUK_NOTIFY_TEMPLATE_ID = (
      local.serco_fms_key_distribution_notify_template_id
    )

    DISTRIBUTION_BUCKET = (
      module.s3-serco-fms-key-distribution-bucket.bucket.id
    )

    FILES_PREFIX = local.serco_fms_key_distribution_files_prefix

    STATE_BUCKET = module.s3-serco-fms-key-distribution-bucket.bucket.id
    STATE_PREFIX = local.serco_fms_key_distribution_state_prefix

    ALLOWLIST_BUCKET = (
      module.s3-serco-fms-key-distribution-bucket.bucket.id
    )

    ALLOWLIST_KEY = local.serco_fms_key_distribution_allowlist_key

    MAX_SECRET_AGE_HOURS         = "48"
    NOTIFY_FILE_RETENTION_PERIOD = "1 week"
  }
}

resource "aws_iam_role" "send_serco_fms_keys_scheduler" {
  name = "send_serco_fms_keys_scheduler_role_${local.environment_shorthand}"

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

resource "aws_iam_role_policy" "send_serco_fms_keys_scheduler" {
  name = "send_serco_fms_keys_scheduler_invoke_policy"
  role = aws_iam_role.send_serco_fms_keys_scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
        ]
        Resource = [
          module.send_serco_fms_keys.lambda_function_arn,
        ]
      }
    ]
  })
}

resource "aws_scheduler_schedule" "send_serco_fms_keys" {
  name        = "send_serco_fms_keys_quarterly_${local.environment_shorthand}"
  description = "Sends encrypted Serco FMS keys after quarterly rotation"
  state = (
    local.serco_fms_key_distribution_enabled ? "ENABLED" : "DISABLED"
  )

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(30 12 ? FEB,MAY,AUG,NOV TUE#2 *)"
  schedule_expression_timezone = "Europe/London"

  target {
    arn      = module.send_serco_fms_keys.lambda_function_arn
    role_arn = aws_iam_role.send_serco_fms_keys_scheduler.arn

    input = jsonencode({
      source = "quarterly-schedule"
    })
  }
}

resource "aws_scheduler_schedule" "send_serco_fms_keys_watchdog" {
  name        = "send_serco_fms_keys_watchdog_${local.environment_shorthand}"
  description = "Checks Serco FMS key distribution completed"
  state = (
    local.serco_fms_key_distribution_enabled ? "ENABLED" : "DISABLED"
  )

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 14 ? FEB,MAY,AUG,NOV TUE#2 *)"
  schedule_expression_timezone = "Europe/London"

  target {
    arn      = module.send_serco_fms_keys.lambda_function_arn
    role_arn = aws_iam_role.send_serco_fms_keys_scheduler.arn

    input = jsonencode({
      source = "quarterly-watchdog"
      mode   = "check_state"
    })
  }
}

resource "aws_cloudwatch_metric_alarm" "send_serco_fms_keys_errors" {
  alarm_name        = "send_serco_fms_keys_errors_${local.environment_shorthand}"
  alarm_description = "Triggered when Serco FMS key distribution fails"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  treat_missing_data  = "notBreaching"

  metric_name = "Errors"
  namespace   = "AWS/Lambda"
  period      = 60
  statistic   = "Sum"

  dimensions = {
    FunctionName = module.send_serco_fms_keys.lambda_function_name
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}

resource "aws_cloudwatch_event_rule" "serco_fms_rotation_failed" {
  name = "serco-fms-key-rotation-failed-${local.environment_shorthand}"

  description = "Alerts when a Secrets Manager rotation failure occurs"

  event_pattern = jsonencode({
    source      = ["aws.secretsmanager"]
    detail-type = ["AWS Service Event via CloudTrail"]
    detail = {
      eventSource = ["secretsmanager.amazonaws.com"]
      eventName = [
        "RotationFailed",
        "RotationAbandoned",
        "TestRotationFailed",
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "serco_fms_rotation_failed" {
  rule = aws_cloudwatch_event_rule.serco_fms_rotation_failed.name
  arn  = aws_sns_topic.emds_alerts.arn

  input_transformer {
    input_paths = {
      event_name = "$.detail.eventName"
      time       = "$.time"
    }

    input_template = join("", [
      "\"Secrets Manager rotation failure in ",
      local.environment_shorthand,
      ": <event_name> at <time>. ",
      "Check the three Serco FMS IAM-user secret rotations.\"",
    ])
  }
}