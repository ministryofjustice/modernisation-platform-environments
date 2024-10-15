##################################################################
# CloudWatch Metric Filters and Log Groups for EC2 Instances Linux
##################################################################

# Linux Log Groups

resource "aws_cloudwatch_log_group" "Linux-Services-Logs" {
  count             = local.is-production == true ? 1 : 0
  name              = "Linux-Services-Logs"
  retention_in_days = 365
}

# Linux Services Metric Filters

resource "aws_cloudwatch_log_metric_filter" "Linux-ServiceStatus-Running" {
  count          = local.is-production == true ? 1 : 0
  name           = "Linux-ServiceStatus-Running"
  log_group_name = aws_cloudwatch_log_group.Linux-Services-Logs[count.index].name
  pattern        = "[date, time, Instance, Service, status=Running]"
  metric_transformation {
    name      = "IsRunning"
    namespace = "ServiceStatus"
    value     = "1"
    dimensions = {
      Instance = "$Instance"
      Service  = "$Service"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "Linux-ServiceStatus-NotRunning" {
  count          = local.is-production == true ? 1 : 0
  name           = "Linux-ServiceStatus-NotRunning"
  log_group_name = aws_cloudwatch_log_group.Linux-Services-Logs[count.index].name
  pattern        = "[date, time, Instance, Service, status!=Running]"
  metric_transformation {
    name      = "IsRunning"
    namespace = "ServiceStatus"
    value     = "0"
    dimensions = {
      Instance = "$Instance"
      Service  = "$Service"
    }
  }
}