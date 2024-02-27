resource "aws_cloudwatch_log_group" "ecs" {
  name              = "${var.env_name}-${var.name}"
  retention_in_days = 7
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
      target_group_arn         = aws_lb_target_group.frontend.arn,
      rds_db_identifier        = aws_db_instance.this[0].identifier
      ecs_service_name         = "${var.env_name}-${var.name}"
      ecs_cluster_name         = local.cluster_name,
      cloudwatch_error_pattern = var.cloudwatch_error_pattern,
    }
  )
}

resource "aws_cloudwatch_dashboard" "ecs" {
  count          = var.create_rds ? 0 : 1
  dashboard_name = "${var.env_name}-${var.name}-dashboard"
  dashboard_body = templatefile(
    "${path.module}/templates/dashboard-ecs.json",
    {
      name                     = var.name,
      env_name                 = var.env_name,
      load_balancer_arn        = var.microservice_lb.arn,
      target_group_arn         = aws_lb_target_group.frontend.arn,
      ecs_service_name         = "${var.env_name}-${var.name}"
      ecs_cluster_name         = local.cluster_name,
      cloudwatch_error_pattern = var.cloudwatch_error_pattern,
    }
  )
}
