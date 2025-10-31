resource "aws_cloudwatch_log_group" "ecs" {
  name              = "${var.env_name}-${var.name}"
  retention_in_days = var.log_retention
  tags              = var.tags
}

resource "aws_cloudwatch_dashboard" "ecs_rds" {
  count          = var.create_rds ? 1 : 0
  dashboard_name = "${var.env_name}-${var.name}-dashboard"
  dashboard_body = templatefile(
    "${path.module}/templates/dashboard-ecs-rds.json",
    {
      name                     = var.name,
      env_name                 = var.env_name,
      load_balancer_arn        = var.microservice_lb.arn,
      target_group_arn         = aws_lb_target_group.frontend[0].arn,
      rds_db_identifier        = aws_db_instance.this[0].identifier
      ecs_service_name         = "${var.env_name}-${var.name}"
      ecs_cluster_name         = local.cluster_name,
      cloudwatch_error_pattern = var.cloudwatch_error_pattern,
    }
  )
}

resource "aws_cloudwatch_dashboard" "ecs_alb_enabled" {
  count          = var.microservice_lb != null ? 1 : 0
  dashboard_name = "${var.env_name}-${var.name}-dashboard"
  dashboard_body = templatefile(
    "${path.module}/templates/dashboard-ecs-alb.json",
    {
      name                     = var.name,
      env_name                 = var.env_name,
      load_balancer_arn        = var.microservice_lb.arn,
      target_group_arn         = aws_lb_target_group.frontend[0].arn,
      ecs_service_name         = "${var.env_name}-${var.name}"
      ecs_cluster_name         = local.cluster_name,
      cloudwatch_error_pattern = var.cloudwatch_error_pattern,
    }
  )
}

resource "aws_cloudwatch_dashboard" "ecs" {
  count          = var.microservice_lb != null ? 0 : 1
  dashboard_name = "${var.env_name}-${var.name}-dashboard"
  dashboard_body = templatefile(
    "${path.module}/templates/dashboard-ecs-no-alb.json",
    {
      name                     = var.name,
      env_name                 = var.env_name,
      ecs_service_name         = "${var.env_name}-${var.name}"
      ecs_cluster_name         = local.cluster_name,
      cloudwatch_error_pattern = var.cloudwatch_error_pattern,
    }
  )
}

