##############################################################
# Eventbridge Rules and Schedules (to invoke Lambda functions)
##############################################################

####################
# Eventbridge Rules 
####################

#####################################################
# Eventbridge Rule to check for Expiring Certificates
#####################################################

# Lambda instances for check_certificate_expiration
locals {
  certificate_expiration_envs = {
    for k, v in local.lambda_instances_map :
    k => v
    if startswith(k, "check_certificate_expiration")
  }
}

# EventBridge Rules for Certificate Expiration
resource "aws_cloudwatch_event_rule" "certificate_approaching_expiration" {
  for_each      = local.certificate_expiration_envs
  name          = "Certificate-Approaching-Expiration-${each.value.env}"
  description   = "PPUD certificate is approaching expiration"
  event_pattern = <<EOF
{
  "source": [ "aws.acm"],
  "detail-type": ["ACM Certificate Approaching Expiration"]
}
EOF
  tags = {
    Function    = each.value.func_name
    Environment = each.value.env
  }
}

# EventBridge Targets for Lambda
resource "aws_cloudwatch_event_target" "trigger_lambda_certificate_approaching_expiration" {
  for_each  = local.certificate_expiration_envs
  rule      = aws_cloudwatch_event_rule.certificate_approaching_expiration[each.key].name
  target_id = "certificate_approaching_expiration_${each.value.env}"
  arn       = aws_lambda_function.lambda_functions[each.key].arn
}

# Lambda Permission for EventBridge
resource "aws_lambda_permission" "allow_cloudwatch_certificate_approaching_expiration" {
  for_each      = local.certificate_expiration_envs
  statement_id  = "AllowExecutionFromEventBridge-${each.value.env}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_functions[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.certificate_approaching_expiration[each.key].arn
}

######################################################
# Eventbridge Rule to check for SSM Parameter Updates
######################################################

# Lambda instances for ssm parameter syncing to waf
locals {
  sync_ssm_to_waf_envs = {
    for k, v in local.lambda_instances_map :
    k => v
    if startswith(k, "sync_ssm_to_waf")
  }
}

resource "aws_cloudwatch_event_rule" "sync_ssm_to_waf" {
  for_each      = local.sync_ssm_to_waf_envs
  name          = "SSM-Parameter-Sync-to-IP-Set-${each.value.env}"
  description   = "Triggers Lambda when SSM parameters change"
  event_pattern = <<EOF
{
  "source": ["aws.ssm"],
  "detail-type": ["Parameter Store Change"],
  "detail": {
    "name": ["/waf/ip_block_list", "circle_ci_waf_ip_set", "ncsc_waf_ip_set"]
  }
}
EOF
  tags = {
    Function    = each.value.func_name
    Environment = each.value.env
  }
}

# EventBridge Targets for Lambda
resource "aws_cloudwatch_event_target" "trigger_lambda_sync_ssm_to_waf" {
  for_each  = local.sync_ssm_to_waf_envs
  rule      = aws_cloudwatch_event_rule.sync_ssm_to_waf[each.key].name
  target_id = "sync_to_ssm_waf_${each.value.env}"
  arn       = aws_lambda_function.lambda_functions[each.key].arn
}

# Lambda Permission for EventBridge
resource "aws_lambda_permission" "allow_cloudwatch_sync_ssm_to_waf" {
  for_each      = local.sync_ssm_to_waf_envs
  statement_id  = "AllowExecutionFromEventBridge-${each.value.env}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_functions[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.sync_ssm_to_waf[each.key].arn
}

#############################################################
# Eventbridge Rule to Auto Tag all Elastic Network Interfaces
#############################################################

locals {
  auto_tag_eni_envs = {
    for k, v in local.lambda_instances_map :
    k => v
    if startswith(k, "auto_tag_eni")
  }
}

resource "aws_cloudwatch_event_rule" "auto_tag_eni" {
  for_each      = local.auto_tag_eni_envs
  name          = "Auto-Tag-ENI-${each.value.env}"
  description   = "Tags all ENIs as they are created"
  event_pattern = <<EOF
{
  "source": ["aws.ec2"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventName": ["CreateNetworkInterface"]
  }
}
EOF
  tags = {
    Function    = each.value.func_name
    Environment = each.value.env
  }
}

resource "aws_cloudwatch_event_target" "trigger_lambda_auto_tag_eni" {
  for_each  = local.auto_tag_eni_envs
  rule      = aws_cloudwatch_event_rule.auto_tag_eni[each.key].name
  target_id = "auto_tag_eni_${each.value.env}"
  arn       = aws_lambda_function.lambda_functions[each.key].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_auto_tag_eni" {
  for_each      = local.auto_tag_eni_envs
  statement_id  = "AllowExecutionFromEventBridge-${each.value.env}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_functions[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.auto_tag_eni[each.key].arn
}

#################################
# EventBridge Scheduler Schedules 
#################################

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
      description  = "Trigger Lambda at 10:00 every Monday"
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
      schedule     = "cron(5 17 ? * MON-FRI *)"
      description  = "Trigger Lambda at 17:00 on weekdays"
      timezone     = "Europe/London"
    }
    ppud_elb_get_trt_data = {
      environments = ["production"]
      schedule     = "cron(0 0 ? * * *)"
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
      schedule     = "cron(0 0 ? * * *)"
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
    wam_waf_analysis = {
      environments = ["development", "preproduction"]
      schedule     = "cron(15 7 ? * MON *)"
      description  = "Trigger Lambda at 07:15 each Monday"
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
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
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
    securityhub_report = local.is-development ? aws_lambda_function.lambda_functions["securityhub_report_development"].arn : (
      local.is-preproduction ? aws_lambda_function.lambda_functions["securityhub_report_preproduction"].arn : (
        local.is-production ? aws_lambda_function.lambda_functions["securityhub_report_production"].arn : null
    ))
    sync_ssm__to_waf = local.is-development ? aws_lambda_function.lambda_functions["sync_ssm_to_waf_development"].arn : (
      local.is-preproduction ? aws_lambda_function.lambda_functions["sync_ssm_to_waf_preproduction"].arn : (
        local.is-production ? aws_lambda_function.lambda_functions["sync_ssm_to_waf_production"].arn : null
    ))
    wam_waf_analysis = local.is-development ? aws_lambda_function.lambda_functions["wam_waf_analysis_development"].arn : (
      local.is-preproduction ? aws_lambda_function.lambda_functions["wam_waf_analysis_preproduction"].arn : null
    )
    #wam_waf_analysis = local.is-development ? aws_lambda_function.lambda_functions["wam_waf_analysis_development"].arn : (
    #  local.is-preproduction ? aws_lambda_function.lambda_functions["wam_waf_analysis_preproduction"].arn : (
    #    local.is-production ? aws_lambda_function.lambda_functions["wam_waf_analysis_production"].arn : null
    #))
    send_cpu_graph                 = local.is-production ? aws_lambda_function.lambda_functions["send_cpu_graph_production"].arn : null
    disable_cpu_alarms             = local.is-production ? aws_lambda_function.lambda_functions["disable_cpu_alarm_production"].arn : null
    enable_cpu_alarms              = local.is-production ? aws_lambda_function.lambda_functions["enable_cpu_alarm_production"].arn : null
    disk_info_report               = local.is-production ? aws_lambda_function.lambda_functions["disk_info_report_production"].arn : null
    email_info_report              = local.is-production ? aws_lambda_function.lambda_functions["ppud_email_report_production"].arn : null
    ppud_elb_get_trt_data          = local.is-production ? aws_lambda_function.lambda_functions["ppud_elb_get_trt_data_production"].arn : null
    ppud_elb_calculate_trt_data    = local.is-production ? aws_lambda_function.lambda_functions["ppud_elb_calculate_trt_data_production"].arn : null
    ppud_elb_get_uptime_data       = local.is-production ? aws_lambda_function.lambda_functions["ppud_elb_get_uptime_data_production"].arn : null
    ppud_elb_calculate_uptime_data = local.is-production ? aws_lambda_function.lambda_functions["ppud_elb_calculate_uptime_data_production"].arn : null
    wam_web_traffic_analysis       = local.is-production ? aws_lambda_function.lambda_functions["wam_web_traffic_analysis_production"].arn : null
    ppud_elb_daily_trt_graph       = local.is-production ? aws_lambda_function.lambda_functions["ppud_elb_graph_trt_data_production"].arn : null
    wam_elb_daily_trt_graph        = local.is-production ? aws_lambda_function.lambda_functions["wam_elb_graph_trt_data_production"].arn : null
    # ppud_elb_daily_connections_graph = local.is-production ? aws_lambda_function.lambda_functions["ppud_elb_count_report_production"].arn : null
    # wam_elb_daily_connections_graph = local.is-production ? aws_lambda_function.lambda_functions["wam_elb_count_report_production"].arn : null
  }
}
