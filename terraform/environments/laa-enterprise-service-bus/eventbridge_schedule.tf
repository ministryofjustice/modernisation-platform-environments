# CWA Extract Schedule
resource "aws_scheduler_schedule" "cwa_extract_schedule" {
  count      = local.environment == "development" ? 1 : 0
  name       = "cwa-extract-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 22 ? * WED *)"

  target {
    arn      = aws_sfn_state_machine.sfn_state_machine.arn
    role_arn = aws_iam_role.scheduler_invoke_sfn_role.arn
  }
}

# CCMS Load Schedule
resource "aws_scheduler_schedule" "ccms_load_schedule" {
  count      = local.environment == "development" ? 1 : 0
  name       = "ccms-load-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 7-19 ? * * *)"

  target {
    arn      = aws_lambda_function.ccms_provider_load.arn
    role_arn = aws_iam_role.scheduler_invoke_lambda_role.arn
  }
}

# MAAT Load Schedule
resource "aws_scheduler_schedule" "maat_load_schedule" {
  name       = "maat-load-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 7-19 ? * * *)"

  target {
    arn      = aws_lambda_function.maat_provider_load.arn
    role_arn = aws_iam_role.scheduler_invoke_lambda_role.arn
  }
}

# CCR Load Schedule
resource "aws_scheduler_schedule" "ccr_load_schedule" {
  count      = local.environment == "development" ? 1 : 0
  name       = "ccr-load-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 7-19 ? * * *)"

  target {
    arn      = aws_lambda_function.ccr_provider_load.arn
    role_arn = aws_iam_role.scheduler_invoke_lambda_role.arn
  }
}

# CCLF Load Schedule
resource "aws_scheduler_schedule" "cclf_load_schedule" {
  count      = local.environment == "development" ? 1 : 0
  name       = "cclf-load-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 7-19 ? * * *)"

  target {
    arn      = aws_lambda_function.cclf_provider_load.arn
    role_arn = aws_iam_role.scheduler_invoke_lambda_role.arn
  }
}