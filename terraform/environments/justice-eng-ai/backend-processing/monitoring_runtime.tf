# Runtime alarms for the web UI and the per-prototype infrastructure. All
# alerts go to the alerts topic defined in monitoring.tf.

locals {
  web_ui_name        = "${local.application_name}-ui"
  prototypes_cluster = "${local.application_name}-prototypes-app"

  # The load balancer dimension is the ARN suffix (app/<name>/<id>).
  runtime_albs = {
    web-ui     = data.aws_lb.web_ui.arn_suffix
    prototypes = data.aws_lb.prototype_deployment.arn_suffix
  }

  alb_metric_alarms = {
    elb-5xx = {
      metric      = "HTTPCode_ELB_5XX_Count"
      threshold   = 5
      description = "The load balancer itself returned 5xx responses"
    }
    target-5xx = {
      metric      = "HTTPCode_Target_5XX_Count"
      threshold   = 10
      description = "Targets returned 5xx responses"
    }
    target-connection-errors = {
      metric      = "TargetConnectionErrorCount"
      threshold   = 5
      description = "The load balancer could not connect to targets"
    }
    rejected-connections = {
      metric      = "RejectedConnectionCount"
      threshold   = 1
      description = "The load balancer rejected connections because it reached its connection limit"
    }
  }

  alb_alarms = {
    for pair in setproduct(keys(local.runtime_albs), keys(local.alb_metric_alarms)) :
    "${pair[0]}-${pair[1]}" => merge(local.alb_metric_alarms[pair[1]], { alb = pair[0], arn_suffix = local.runtime_albs[pair[0]] })
  }

  # Service events (including failed deployments) and stopped tasks, delivered to Slack.
  ecs_event_clusters = {
    web-ui     = local.web_ui_name
    prototypes = local.prototypes_cluster
  }

  ecs_event_kinds = {
    service-error = {
      description = "An ECS service reported an error, such as tasks failing to start or placement failing"
      detail_type = "ECS Service Action"
      detail      = { eventType = ["ERROR"] }
      title       = "ECS service error"
      input_paths = { cluster = "$.detail.clusterArn", event = "$.detail.eventName", reason = "$.detail.reason" }
      body        = "*Cluster:* <cluster>\\n*Event:* <event>\\n*Reason:* <reason>"
    }
    deployment-failed = {
      description = "An ECS service deployment failed"
      detail_type = "ECS Deployment State Change"
      detail      = { eventType = ["ERROR"] }
      title       = "ECS deployment failed"
      input_paths = { cluster = "$.detail.clusterArn", event = "$.detail.eventName", reason = "$.detail.reason" }
      body        = "*Cluster:* <cluster>\\n*Event:* <event>\\n*Reason:* <reason>"
    }
    task-stopped = {
      description = "An ECS task stopped because it failed to start or an essential container exited"
      detail_type = "ECS Task State Change"
      detail      = { lastStatus = ["STOPPED"], stopCode = ["TaskFailedToStart", "EssentialContainerExited"] }
      title       = "ECS task stopped unexpectedly"
      input_paths = { cluster = "$.detail.clusterArn", group = "$.detail.group", reason = "$.detail.stoppedReason" }
      body        = "*Cluster:* <cluster>\\n*Group:* <group>\\n*Reason:* <reason>"
    }
  }

  ecs_event_rules = {
    for pair in setproduct(keys(local.ecs_event_clusters), keys(local.ecs_event_kinds)) :
    "${pair[0]}-${pair[1]}" => merge(local.ecs_event_kinds[pair[1]], {
      cluster_arn = "arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:cluster/${local.ecs_event_clusters[pair[0]]}"
      cluster     = pair[0]
    })
  }
}

# Created by the web-ui and prototypes-infra roots, so those must be applied first.
data "aws_cloudwatch_log_group" "web_ui" {
  name = "/ecs/${local.web_ui_name}"
}

data "aws_lb" "web_ui" {
  name = local.web_ui_name
}

# ---------- Load balancers (web UI and the shared prototype ALB) ----------

resource "aws_cloudwatch_metric_alarm" "alb" {
  for_each = local.alb_alarms

  alarm_name          = "${local.application_name}-${local.environment}-${each.key}"
  alarm_description   = "${each.value.description} (${each.value.alb} load balancer)."
  namespace           = "AWS/ApplicationELB"
  metric_name         = each.value.metric
  dimensions          = { LoadBalancer = each.value.arn_suffix }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = each.value.threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  tags                = local.tags
}

# One alarm across every target group on the load balancer, so it also covers
# the target group created for each prototype.
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  for_each = local.runtime_albs

  alarm_name          = "${local.application_name}-${local.environment}-${each.key}-unhealthy-hosts"
  alarm_description   = "A target group on the ${each.key} load balancer has unhealthy targets."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  tags                = local.tags

  metric_query {
    id          = "unhealthy"
    expression  = "SELECT MAX(UnHealthyHostCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer, TargetGroup) WHERE LoadBalancer = '${each.value}'"
    period      = 60
    return_data = true
  }
}

# ---------- Web UI service ----------

resource "aws_cloudwatch_metric_alarm" "web_ui_running_tasks" {

  alarm_name          = "${local.application_name}-${local.environment}-web-ui-no-running-tasks"
  alarm_description   = "The web UI ECS service has no running tasks."
  namespace           = "ECS/ContainerInsights"
  metric_name         = "RunningTaskCount"
  dimensions          = { ClusterName = local.web_ui_name, ServiceName = local.web_ui_name }
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  tags                = local.tags
}

resource "aws_cloudwatch_metric_alarm" "web_ui_utilisation" {
  for_each = { cpu = "CPUUtilization", memory = "MemoryUtilization" }

  alarm_name          = "${local.application_name}-${local.environment}-web-ui-high-${each.key}"
  alarm_description   = "The web UI service ${each.key} utilisation is above 85%."
  namespace           = "AWS/ECS"
  metric_name         = each.value
  dimensions          = { ClusterName = local.web_ui_name, ServiceName = local.web_ui_name }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = 85
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  tags                = local.tags
}

# The UI logs JSON (MPAPB_LOG_FORMAT=json). Bedrock failures also match this filter;
# monitoring.tf has separate Bedrock alarms that say what kind of failure it was.
resource "aws_cloudwatch_log_metric_filter" "web_ui_errors" {

  name           = "${local.application_name}-web-ui-errors"
  log_group_name = data.aws_cloudwatch_log_group.web_ui.name
  pattern        = "{ $.level = \"ERROR\" }"

  metric_transformation {
    name      = "WebUiErrors"
    namespace = "${local.metric_namespace}/WebUi"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "web_ui_errors" {

  alarm_name          = "${local.application_name}-${local.environment}-web-ui-errors"
  alarm_description   = "The web UI logged errors. Search the ${data.aws_cloudwatch_log_group.web_ui.name} log group for level ERROR."
  namespace           = "${local.metric_namespace}/WebUi"
  metric_name         = "WebUiErrors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  tags                = local.tags

  depends_on = [aws_cloudwatch_log_metric_filter.web_ui_errors]
}

# ---------- ECS clusters (web UI and prototypes) ----------
# Prototype services are created at runtime, so cluster events cover them rather than
# per-service metrics.

resource "aws_cloudwatch_event_rule" "ecs" {
  for_each = local.ecs_event_rules

  name        = "${local.application_name}-${each.key}"
  description = "${each.value.description} (${each.value.cluster} cluster)."
  tags        = local.tags

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = [each.value.detail_type]
    detail      = merge(each.value.detail, { clusterArn = [each.value.cluster_arn] })
  })
}

resource "aws_cloudwatch_event_target" "ecs" {
  for_each = local.ecs_event_rules

  rule = aws_cloudwatch_event_rule.ecs[each.key].name
  arn  = aws_sns_topic.alerts.arn

  input_transformer {
    input_paths    = each.value.input_paths
    input_template = "{\"version\":\"1.0\",\"source\":\"custom\",\"content\":{\"textType\":\"client-markdown\",\"title\":\"[${local.environment}] ${each.value.title} (${each.value.cluster})\",\"description\":\"${each.value.body}\"}}"
  }

  depends_on = [aws_sns_topic_policy.alerts]
}

# ---------- DynamoDB ----------
# Tables are created per prototype, so these alarms query every table in the account.

resource "aws_cloudwatch_metric_alarm" "dynamodb" {
  for_each = {
    system-errors = { metric = "SystemErrors", threshold = 1, description = "DynamoDB returned server-side (5xx) errors" }
    throttled     = { metric = "ThrottledRequests", threshold = 5, description = "DynamoDB throttled requests" }
  }

  alarm_name          = "${local.application_name}-${local.environment}-dynamodb-${each.key}"
  alarm_description   = "${each.value.description} on one or more tables."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  tags                = local.tags

  metric_query {
    id          = "errors"
    expression  = "SELECT SUM(${each.value.metric}) FROM SCHEMA(\"AWS/DynamoDB\", TableName, Operation)"
    period      = 300
    return_data = true
  }
}
