#######################################
# CloudWatch Log Groups for OIA
#######################################

# ECS Application Logs
resource "aws_cloudwatch_log_group" "opahub_ecs" {
  name              = "${local.opa_app_name}-ecs"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("%s-ecs-logs", local.opa_app_name)) }
  )
}

# RDS Logs - Alert
resource "aws_cloudwatch_log_group" "opahub_rds_alert" {
  name              = "${local.opa_app_name}-rds-alert"
  retention_in_days = local.application_data.accounts[local.environment].db_log_retention_days

  tags = merge(local.tags,
    { Name = lower(format("%s-rds-alert-logs", local.opa_app_name)) }
  )
}

# RDS Logs - Audit
resource "aws_cloudwatch_log_group" "opahub_rds_audit" {
  name              = "${local.opa_app_name}-rds-audit"
  retention_in_days = local.application_data.accounts[local.environment].db_log_retention_days

  tags = merge(local.tags,
    { Name = lower(format("%s-rds-audit-logs", local.opa_app_name)) }
  )
}

# RDS Logs - Listener
resource "aws_cloudwatch_log_group" "opahub_rds_listener" {
  name              = "${local.opa_app_name}-rds-listener"
  retention_in_days = local.application_data.accounts[local.environment].db_log_retention_days

  tags = merge(local.tags,
    { Name = lower(format("%s-rds-listener-logs", local.opa_app_name)) }
  )
}
