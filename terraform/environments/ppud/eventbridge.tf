################################################
# Eventbridge Rules (to invoke Lambda functions)
################################################

# TBA

##############################################################
# EventBridge Scheduler Schedules (to invoke Lambda functions)
##############################################################

locals {
  # EventBridge Scheduler configurations
  lambda_schedules = {
    securityhub_report = {
      environments = ["development", "preproduction", "production"]
      schedule     = "cron(0 7 ? * MON-FRI *)"
      description  = "Trigger Lambda at 07:00 each Monday through Friday"
      timezone     = "Europe/London"
    }
    disable_cpu_alarms = {
      environments = ["production"]
      schedule     = "cron(0 20 ? * FRI *)"
      description  = "Trigger Lambda at 20:00 every Friday"
      timezone     = "Europe/London"
    }
    enable_cpu_alarms = {
      environments = ["production"]
      schedule     = "cron(0 9 ? * MON *)"
      description  = "Trigger Lambda at 09:00 every Monday"
      timezone     = "Europe/London"
    }
    disk_info_report = {
      environments = ["production"]
      schedule     = "cron(0 7 ? * MON *)"
      description  = "Trigger Lambda at 07:00 each Monday"
      timezone     = "Europe/London"
    }
    email_info_report = {
      environments = ["production"]
      schedule     = "cron(15 7 ? * MON *)"
      description  = "Trigger Lambda at 07:15 each Monday"
      timezone     = "Europe/London"
    }
    send_cpu_graph = {
      environments = ["production"]
      schedule     = "cron(5 16 ? * MON-FRI *)"
      description  = "Trigger Lambda at 17:00 on weekdays"
      timezone     = "Europe/London"
    }
    ppud_elb_get_trt_data = {
      environments = ["production"]
      schedule     = "cron(0 0 ? * * *)" # check IIS log timings
      description  = "Trigger Lambda at 00:00 every day"
      timezone     = "Europe/London"
    }
    ppud_elb_calculate_trt_data = {
      environments = ["production"]
      schedule     = "cron(0 2 1 * ? *)"
      description  = "Trigger Lambda at 02:00 on the 1st day of every month"
      timezone     = "Europe/London"
    }
    ppud_elb_get_uptime_data = {
      environments = ["production"]
      schedule     = "cron(0 0 ? * * *)" # check IIS log timings
      description  = "Trigger Lambda at 00:00 every day"
      timezone     = "Europe/London"
    }
    ppud_elb_calculate_uptime_data = {
      environments = ["production"]
      schedule     = "cron(0 2 1 * ? *)"
      description  = "Trigger Lambda at 02:00 on the 1st day of every month"
      timezone     = "Europe/London"
    }
    wam_web_traffic_analysis = {
      environments = ["production"]
      schedule     = "cron(0 1 15 * ? *)"
      description  = "Trigger Lambda at 01:00 every 15th of the month"
      timezone     = "Europe/London"
    }
    ppud_elb_daily_trt_graph = {
      environments = ["production"]
      schedule     = "cron(0 18 ? * MON-FRI *)"
      description  = "Trigger Lambda at 18:00 each Monday through Friday"
      timezone     = "Europe/London"
    }
    wam_elb_daily_trt_graph = {
      environments = ["production"]
      schedule     = "cron(0 18 ? * MON-FRI *)"
      description  = "Trigger Lambda at 18:00 each Monday through Friday"
      timezone     = "Europe/London"
    }
    /*
    ppud_elb_daily_connections_graph = {
      environments = ["production"]
      schedule     = "cron(15 20 ? * MON-FRI *)"
      description  = "Trigger Lambda at 20:15 each Monday through Friday"
      timezone     = "Europe/London"
    }
    wam_elb_daily_connections_graph = {
      environments = ["production"]
      schedule     = "cron(15 20 ? * MON-FRI *)"
      description  = "Trigger Lambda at 20:15 each Monday through Friday"
      timezone     = "Europe/London"
    }
    */
  }

  # Generate schedule map for current environment
  current_schedules = {
    for name, config in local.lambda_schedules :
    name => config
    if contains(config.environments, local.environment)
  }
}

# IAM role for EventBridge Scheduler
resource "aws_iam_role" "eventbridge_scheduler_role" {
  name = "eventbridge-scheduler-role-${local.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for EventBridge Scheduler
resource "aws_iam_role_policy" "eventbridge_scheduler_policy" {
  name = "eventbridge-scheduler-policy-${local.environment}"
  role = aws_iam_role.eventbridge_scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = [for arn in values(local.lambda_function_arns) : arn if arn != null]
      }
    ]
  })
}

# Dynamic EventBridge Schedules
resource "aws_scheduler_schedule" "lambda_schedules" {
  # checkov:skip=CKV_AWS_297: "EventBridge Scheduler Schedule will use AWS managed keys"
  for_each = local.current_schedules

  name        = "${each.key}_schedule_${local.environment}"
  description = each.value.description
  state       = "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = each.value.schedule
  schedule_expression_timezone = each.value.timezone

  target {
    arn      = local.lambda_function_arns[each.key]
    role_arn = aws_iam_role.eventbridge_scheduler_role.arn
  }
}

# Lambda function ARN mapping
locals {
  lambda_function_arns = {
    securityhub_report = local.is-development ? aws_lambda_function.terraform_lambda_func_securityhub_report_dev[0].arn : (
      local.is-preproduction ? aws_lambda_function.terraform_lambda_func_securityhub_report_uat[0].arn : (
        local.is-production ? aws_lambda_function.terraform_lambda_func_securityhub_report_prod[0].arn : null
      )
    )
    send_cpu_graph = local.is-production ? aws_lambda_function.terraform_lambda_func_send_cpu_graph_prod[0].arn : null
    disable_cpu_alarms = local.is-production ? aws_lambda_function.terraform_lambda_disable_cpu_alarm_prod[0].arn : null
    enable_cpu_alarms = local.is-production ? aws_lambda_function.terraform_lambda_enable_cpu_alarm_prod[0].arn : null
    disk_info_report = local.is-production ? aws_lambda_function.terraform_lambda_func_disk_info_report_prod[0].arn : null
    email_info_report = local.is-production ? aws_lambda_function.terraform_lambda_func_ppud_email_report_prod[0].arn : null
    ppud_elb_get_trt_data = local.is-production ? aws_lambda_function.terraform_lambda_func_ppud_elb_trt_data_prod[0].arn : null
    ppud_elb_calculate_trt_data = local.is-production ? aws_lambda_function.terraform_lambda_func_ppud_elb_trt_calculate_prod[0].arn : null
    ppud_elb_get_uptime_data = local.is-production ? aws_lambda_function.terraform_lambda_func_ppud_elb_uptime_data_prod[0].arn : null
    ppud_elb_calculate_uptime_data = local.is-production ? aws_lambda_function.terraform_lambda_func_ppud_elb_uptime_calculate_prod[0].arn : null
    wam_web_traffic_analysis = local.is-production ? aws_lambda_function.terraform_lambda_func_wam_web_traffic_analysis_prod[0].arn : null
    ppud_elb_daily_trt_graph = local.is-production ? aws_lambda_function.terraform_lambda_func_ppud_elb_trt_graph_prod[0].arn : null
    wam_elb_daily_trt_graph = local.is-production ? aws_lambda_function.terraform_lambda_func_wam_elb_trt_graph_prod[0].arn : null
#   ppud_elb_daily_connections_graph = local.is-production ? aws_lambda_function.terraform_lambda_func_ppud_elb_report_prod[0].arn : null
#   wam_elb_daily_connections_graph = local.is-production ? aws_lambda_function.terraform_lambda_func_wam_elb_report_prod[0].arn : null
  }
}