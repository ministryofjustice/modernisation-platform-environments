# SNS topic for monitoring to send alarms to
resource "aws_sns_topic" "dms_alerting" {
  name              = "delius-dms-alerting"
  kms_master_key_id = var.account_config.kms_keys.general_shared
}

# Create a map of all possible replication tasks, so those that exist may have alarms applied to them.
# Note that the key of this map cannot be an apply time value, so cannot be the ARN or ID of the
# replication tasks - these should appear only as values.
locals {
  aws_dms_replication_tasks = merge(
    try(var.dms_config.user_target_endpoint.write_database, null) == null ? {} : {
      user_inbound_replication = {
        replication_task_arn = aws_dms_replication_task.user_inbound_replication[0].replication_task_arn,
        replication_task_id  = aws_dms_replication_task.user_inbound_replication[0].replication_task_id
      }
    },
    { for k in keys(local.client_account_map) :
      "business_interaction_inbound_replication_from_${k}" => {
        replication_task_arn = aws_dms_replication_task.business_interaction_inbound_replication[k].replication_task_arn
        replication_task_id  = aws_dms_replication_task.business_interaction_inbound_replication[k].replication_task_id
      }
    },
    { for k in keys(local.client_account_map) :
      "audited_interaction_inbound_replication_from_${k}" => {
        replication_task_arn = aws_dms_replication_task.audited_interaction_inbound_replication[k].replication_task_arn
        replication_task_id  = aws_dms_replication_task.audited_interaction_inbound_replication[k].replication_task_id
      }
    },
    { for k in keys(local.client_account_map) :
      "audited_interaction_checksum_inbound_replication_from_${k}" => {
        replication_task_arn = aws_dms_replication_task.audited_interaction_checksum_inbound_replication[k].replication_task_arn
        replication_task_id  = aws_dms_replication_task.audited_interaction_checksum_inbound_replication[k].replication_task_id
      }
    },
    try(var.dms_config.audit_source_endpoint.read_database, null) == null ? {} : {
      audited_interaction_outbound_replication = {
        replication_task_arn = aws_dms_replication_task.audited_interaction_outbound_replication[0].replication_task_arn
        replication_task_id  = aws_dms_replication_task.audited_interaction_outbound_replication[0].replication_task_id
      }
    },
    { for k in keys(local.client_account_map) :
      "user_outbound_replication_to_${k}" => {
        replication_task_arn = aws_dms_replication_task.user_outbound_replication[k].replication_task_arn
        replication_task_id  = aws_dms_replication_task.user_outbound_replication[k].replication_task_id
      }
    },
    try(var.dms_config.audit_source_endpoint.read_database, null) == null ? {} : {
      business_interaction_outbound_replication = {
        replication_task_arn = aws_dms_replication_task.business_interaction_outbound_replication[0].replication_task_arn
        replication_task_id  = aws_dms_replication_task.business_interaction_outbound_replication[0].replication_task_id
      }
    },
    try(var.dms_config.audit_source_endpoint.read_database, null) == null ? {} : {
      audited_interaction_checksum_outbound_replication = {
        replication_task_arn = aws_dms_replication_task.audited_interaction_checksum_outbound_replication[0].replication_task_arn
        replication_task_id  = aws_dms_replication_task.audited_interaction_checksum_outbound_replication[0].replication_task_id
      }
    }
  )
}



resource "aws_cloudwatch_metric_alarm" "dms_cdc_latency_source" {
  for_each            = local.aws_dms_replication_tasks
  alarm_name          = "dms-cdc-latency-source-${each.value.replication_task_id}"
  alarm_description   = "High CDC source latency for dms replication task for ${each.value.replication_task_id}"
  namespace           = "AWS/DMS"
  statistic           = "Average"
  metric_name         = "CDCLatencySource"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  evaluation_periods  = 2
  period              = 30
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.dms_alerting.arn]
  ok_actions          = [aws_sns_topic.dms_alerting.arn]
  dimensions = {
    ReplicationInstanceIdentifier = aws_dms_replication_instance.dms_replication_instance.replication_instance_id
    # We only need to final element of the replication task ID (after the last :)
    ReplicationTaskIdentifier = split(":", each.value.replication_task_arn)[length(split(":", each.value.replication_task_arn)) - 1]
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "dms_cdc_latency_target" {
  for_each            = local.aws_dms_replication_tasks
  alarm_name          = "dms-cdc-latency-target-${each.value.replication_task_id}"
  alarm_description   = "High CDC target latency for dms replication task for ${each.value.replication_task_id}"
  namespace           = "AWS/DMS"
  statistic           = "Average"
  metric_name         = "CDCLatencyTarget"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  evaluation_periods  = 2
  period              = 30
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.dms_alerting.arn]
  ok_actions          = [aws_sns_topic.dms_alerting.arn]
  dimensions = {
    ReplicationInstanceIdentifier = aws_dms_replication_instance.dms_replication_instance.replication_instance_id
    # We only need to final element of the replication task ID (after the last :)
    ReplicationTaskIdentifier = split(":", each.value.replication_task_arn)[length(split(":", each.value.replication_task_arn)) - 1]
  }
  tags = var.tags
}

# Pager duty integration

# Get the map of pagerduty integration keys from the modernisation platform account
data "aws_secretsmanager_secret" "pagerduty_integration_keys" {
  provider = aws.modernisation-platform
  name     = "pagerduty_integration_keys"
}

data "aws_secretsmanager_secret_version" "pagerduty_integration_keys" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.pagerduty_integration_keys.id
}

# Add a local to get the keys
locals {
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)
  integration_key_lookup     = var.dms_config.is-production ? "delius_oracle_prod_alarms" : "delius_oracle_nonprod_alarms"
}

# link the sns topic to the service
# Non-Prod alerts channel: #delius-aws-oracle-dev-alerts
# Prod alerts channel:     #delius-aws-oracle-prod-alerts
module "pagerduty_core_alerts" {
  depends_on = [
    aws_sns_topic.dms_alerting
  ]
  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = [aws_sns_topic.dms_alerting.name]
  pagerduty_integration_key = local.pagerduty_integration_keys[local.integration_key_lookup]
}
