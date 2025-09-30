#######################################
# CloudWatch Log Groups for OIA
#######################################

# ECS Application Logs
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "${local.application_name}-ecs"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-ecs-logs", local.application_name, local.environment)) }
  )
}

# RDS Logs - Alert
resource "aws_cloudwatch_log_group" "rds_alert" {
  name              = "${local.application_name}-rds-alert"
  retention_in_days = local.application_data.accounts[local.environment].db_log_retention_days

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-rds-alert-logs", local.application_name, local.environment)) }
  )
}

# RDS Logs - Audit
resource "aws_cloudwatch_log_group" "rds_audit" {
  name              = "${local.application_name}-rds-audit"
  retention_in_days = local.application_data.accounts[local.environment].db_log_retention_days

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-rds-audit-logs", local.application_name, local.environment)) }
  )
}

# RDS Logs - Listener
resource "aws_cloudwatch_log_group" "rds_listener" {
  name              = "${local.application_name}-rds-listener"
  retention_in_days = local.application_data.accounts[local.environment].db_log_retention_days

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-rds-listener-logs", local.application_name, local.environment)) }
  )
}
