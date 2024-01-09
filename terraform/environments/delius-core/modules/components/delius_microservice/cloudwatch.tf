resource "aws_cloudwatch_log_group" "ecs" {
  name              = "${var.env_name}-${var.name}"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_cloudwatch_dashboard" "jitbit" {
  dashboard_name = "${var.env_name}-${var.name}-dashboard"
  dashboard_body = templatefile(
    "${path.module}/templates/dashboard.json",
    {
      name              = var.name,
      env_name          = var.env_name,
      load_balancer_arn = var.microservice_lb_arn,
      target_group_arn  = aws_lb_target_group.this.arn,
      rds_db_identifier = aws_db_instance.this.identifier,
      ecs_service_name  = "${var.env_name}-${var.name}"
      ecs_cluster_name  = local.cluster_name

    }
  )
}
