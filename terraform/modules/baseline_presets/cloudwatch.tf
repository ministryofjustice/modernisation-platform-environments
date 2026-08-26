locals {
  cloudwatch_event_rules = merge(
    can(var.options.sns_topics.pagerduty_integrations["pagerduty"]) ? {
      aws-health = {
        event_pattern = jsonencode({
          source = [
            "aws.health"
          ]
        })
        sns_topic_name_or_arn = "pagerduty"
      }
    } : {}
  )

  cloudwatch_log_groups_retention_default = contains(["preproduction", "production"], var.environment.environment) ? 400 : 30 # 13 month retention on prod as per MOJ guidance
  cloudwatch_log_groups_filter = flatten([
    var.options.enable_ec2_session_manager_cloudwatch_logs ? ["session-manager-logs"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["cwagent-var-log-messages"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["cwagent-var-log-secure"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["cwagent-windows-system"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["cwagent-windows-application"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["cwagent-windows-security"] : [],
    var.options.enable_ec2_cloud_watch_agent ? ["cwagent-windows-security"] : [],
    var.options.enable_ec2_cloud_watch_agent && var.options.enable_ec2_oracle_enterprise_managed_server ? ["cwagent-oracle-listener-log"] : [],
  ])

  cloudwatch_log_groups = {
    session-manager-logs = {
      retention_in_days = coalesce(var.options.cloudwatch_log_groups_retention_in_days, local.cloudwatch_log_groups_retention_default)
    }
    cwagent-var-log-messages = {
      retention_in_days = coalesce(var.options.cloudwatch_log_groups_retention_in_days, local.cloudwatch_log_groups_retention_default)
    }
    cwagent-var-log-secure = {
      retention_in_days = coalesce(var.options.cloudwatch_log_groups_retention_in_days, local.cloudwatch_log_groups_retention_default)
    }
    cwagent-windows-system = {
      retention_in_days = coalesce(var.options.cloudwatch_log_groups_retention_in_days, local.cloudwatch_log_groups_retention_default)
    }
    cwagent-windows-application = {
      retention_in_days = coalesce(var.options.cloudwatch_log_groups_retention_in_days, local.cloudwatch_log_groups_retention_default)
    }
    cwagent-windows-security = {
      retention_in_days = coalesce(var.options.cloudwatch_log_groups_retention_in_days, local.cloudwatch_log_groups_retention_default)
    }
    cwagent-oracle-listener-log = {
      retention_in_days = coalesce(var.options.cloudwatch_log_groups_retention_in_days, local.cloudwatch_log_groups_retention_default)
    }
  }
}

