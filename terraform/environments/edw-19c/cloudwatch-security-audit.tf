##################################################################################################################
### EDW Security Alerting
###
### Detects tampering with the EDW database credentials and posts to #laa-alerts-oas-edw:
###   1. Changes to the DB master password secret in Secrets Manager (CloudTrail -> EventBridge)
###   2. Changes to the RDS instance itself, e.g. master password reset (CloudTrail -> EventBridge)
###   3. Repeated failed DB logons (ORA-01017) from the exported RDS audit log (metric filter -> alarm -> SNS)
##################################################################################################################

locals {
  enable_edw_security_alerts = local.enable_edw_rds

  db_instance_identifier = "${local.application_name}-${local.environment}"
  db_audit_log_group     = "/aws/rds/instance/${local.db_instance_identifier}/audit"

  # Alarm when this many failed logons happen within one evaluation period.
  failed_db_logon_threshold      = 5
  failed_db_logon_period_seconds = 300
}

######################################
### EventBridge Rules
######################################

# Write and policy actions on the DB master password secret. Matches the secret by name or ARN,
# since callers can pass either as SecretId.
resource "aws_cloudwatch_event_rule" "db_secret_changes" {
  count       = local.enable_edw_security_alerts ? 1 : 0
  name        = "${local.application_name}-${local.environment}-db-secret-changes"
  description = "Capture API calls that change the EDW DB credentials secret"

  event_pattern = jsonencode({
    source      = ["aws.secretsmanager"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["secretsmanager.amazonaws.com"]
      eventName = [
        "PutSecretValue",
        "UpdateSecret",
        "UpdateSecretVersionStage",
        "RotateSecret",
        "CancelRotateSecret",
        "DeleteSecret",
        "RestoreSecret",
        "PutResourcePolicy",
        "DeleteResourcePolicy",
        "ReplicateSecretToRegions"
      ]
      requestParameters = {
        secretId = [{ wildcard = "*${aws_secretsmanager_secret.rds_password_secret_new[0].name}*" }]
      }
    }
  })

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-db-secret-changes" }
  )
}

# Modifications to the EDW RDS instance. The Lambda flags calls that set masterUserPassword,
# which changes the DB password directly and leaves the stored secret out of sync.
resource "aws_cloudwatch_event_rule" "db_instance_changes" {
  count       = local.enable_edw_security_alerts ? 1 : 0
  name        = "${local.application_name}-${local.environment}-db-instance-changes"
  description = "Capture ModifyDBInstance calls against the EDW RDS instance"

  event_pattern = jsonencode({
    source      = ["aws.rds"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["rds.amazonaws.com"]
      eventName   = ["ModifyDBInstance"]
      requestParameters = {
        dBInstanceIdentifier = [{ wildcard = "*${local.db_instance_identifier}" }]
      }
    }
  })

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-db-instance-changes" }
  )
}

######################################
### Credential Change CloudWatch Logs
######################################

# Stores credential change events and provides the source for the Slack subscription.
resource "aws_cloudwatch_log_group" "db_credential_changes" {
  #checkov:skip=CKV_AWS_158: CloudTrail event copies, no KMS encryption required
  count             = local.enable_edw_security_alerts ? 1 : 0
  name              = "/aws/events/${local.application_name}/${local.environment}/db-credential-changes"
  retention_in_days = 90

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-db-credential-change-events" }
  )
}

# Allows both EventBridge rules to write to the log group.
data "aws_iam_policy_document" "db_credential_changes_log_policy" {
  count = local.enable_edw_security_alerts ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = ["${aws_cloudwatch_log_group.db_credential_changes[0].arn}:*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        aws_cloudwatch_event_rule.db_secret_changes[0].arn,
        aws_cloudwatch_event_rule.db_instance_changes[0].arn,
      ]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "db_credential_changes_log_policy" {
  count           = local.enable_edw_security_alerts ? 1 : 0
  policy_document = data.aws_iam_policy_document.db_credential_changes_log_policy[0].json
  policy_name     = "${local.application_name}-${local.environment}-db-credential-changes"
}

resource "aws_cloudwatch_event_target" "db_secret_changes_log_group" {
  count          = local.enable_edw_security_alerts ? 1 : 0
  rule           = aws_cloudwatch_event_rule.db_secret_changes[0].name
  target_id      = "DbSecretChangesCloudWatchLogs"
  arn            = aws_cloudwatch_log_group.db_credential_changes[0].arn
  event_bus_name = "default"

  depends_on = [aws_cloudwatch_log_resource_policy.db_credential_changes_log_policy]
}

resource "aws_cloudwatch_event_target" "db_instance_changes_log_group" {
  count          = local.enable_edw_security_alerts ? 1 : 0
  rule           = aws_cloudwatch_event_rule.db_instance_changes[0].name
  target_id      = "DbInstanceChangesCloudWatchLogs"
  arn            = aws_cloudwatch_log_group.db_credential_changes[0].arn
  event_bus_name = "default"

  depends_on = [aws_cloudwatch_log_resource_policy.db_credential_changes_log_policy]
}

######################################
### Failed DB Logons
######################################

# Counts ORA-01017 (invalid username/password) records in the exported Oracle audit log.
# Oracle writes the error code as STATUS:[4] '1017' (SYS) or RETURNCODE:[4] '1017' (other users).
# Logons by non-SYS users only reach this log when audit_trail = OS (set in the parameter group in rds.tf,
# applied on reboot) and a DBA has run "AUDIT SESSION WHENEVER NOT SUCCESSFUL;" in the database.
resource "aws_cloudwatch_log_metric_filter" "failed_db_logons" {
  count          = local.enable_edw_security_alerts ? 1 : 0
  name           = "${local.application_name}-${local.environment}-failed-db-logons"
  log_group_name = local.db_audit_log_group
  pattern        = "\"'1017'\""

  metric_transformation {
    name          = "FailedDBLogons"
    namespace     = "EDW/Security"
    value         = "1"
    default_value = "0"
  }

  # RDS creates the audit log group once the instance starts exporting logs.
  depends_on = [aws_db_instance.edw_rds_instance]
}

# Alarming on a count, rather than streaming each log line, keeps a burst of failures to one message.
resource "aws_cloudwatch_metric_alarm" "failed_db_logons" {
  count               = local.enable_edw_security_alerts ? 1 : 0
  alarm_name          = "${local.application_name}-${local.environment}-failed-db-logons"
  alarm_description   = "EDW database rejected ${local.failed_db_logon_threshold} or more logons (ORA-01017) in ${local.failed_db_logon_period_seconds / 60} minutes. Check whether the credentials in ${aws_secretsmanager_secret.rds_password_secret_new[0].name} still match the database."
  namespace           = "EDW/Security"
  metric_name         = "FailedDBLogons"
  statistic           = "Sum"
  period              = local.failed_db_logon_period_seconds
  evaluation_periods  = 1
  threshold           = local.failed_db_logon_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts[0].arn]
  ok_actions          = [aws_sns_topic.security_alerts[0].arn]

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-failed-db-logons" }
  )
}

######################################
### SNS Topic for Security Alarms
######################################

resource "aws_sns_topic" "security_alerts" {
  #checkov:skip=CKV_AWS_26: CloudWatch alarms cannot publish to topics encrypted with the AWS managed SNS key
  count = local.enable_edw_security_alerts ? 1 : 0
  name  = "${local.application_name}-${local.environment}-security-alerts"

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-security-alerts" }
  )
}

resource "aws_sns_topic_subscription" "security_alerts_lambda" {
  count     = local.enable_edw_security_alerts ? 1 : 0
  topic_arn = aws_sns_topic.security_alerts[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.security_alerts_slack[0].arn
}
