# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "log_group_edrms" {
  name              = "${local.application_name}-ecs"
  retention_in_days = 30

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-logs", local.application_name, local.environment)) }
  )
}

resource "aws_cloudwatch_log_stream" "log_stream_edrms" {
  name           = "${local.application_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.log_group_edrms.name
}

#--RDS
resource "aws_cloudwatch_log_group" "rds_alert" {
  name              = "/aws/rds/instance/oracle-db/alert"
  retention_in_days = local.application_data.accounts[local.environment].db_log_retention_days
}

resource "aws_cloudwatch_log_group" "rds_audit" {
  name              = "/aws/rds/instance/oracle-db/audit"
  retention_in_days = local.application_data.accounts[local.environment].db_log_retention_days
}

resource "aws_cloudwatch_log_group" "rds_listener" {
  name              = "/aws/rds/instance/oracle-db/listener"
  retention_in_days = local.application_data.accounts[local.environment].db_log_retention_days
}