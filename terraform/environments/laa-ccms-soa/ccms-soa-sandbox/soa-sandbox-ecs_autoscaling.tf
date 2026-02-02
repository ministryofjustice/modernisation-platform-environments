#--Admin
resource "aws_appautoscaling_target" "target_admin" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.admin.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 1
}

resource "aws_appautoscaling_policy" "up_admin" {
  name               = "${local.component_name}-${local.environment}-admin-scale-up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.admin.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [
    aws_appautoscaling_target.target_admin,
  ]
}

resource "aws_appautoscaling_policy" "down_admin" {
  name               = "${local.component_name}-${local.environment}-admin-scale-down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.soasandbox-main.name}/${aws_ecs_service.soasandbox-admin.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [
    aws_appautoscaling_target.target_admin,
  ]
}

#--Managed
resource "aws_appautoscaling_target" "target_managed" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.managed.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 6
}

resource "aws_appautoscaling_policy" "up_managed" {
  name               = "${local.component_name}-${local.environment}-scale-up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.soasandbox-main.name}/${aws_ecs_service.soasandbox-managed.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [
    aws_appautoscaling_target.target_managed,
  ]
}

resource "aws_appautoscaling_policy" "down_managed" {
  name               = "${local.component_name}-${local.environment}-scale-down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.soasandbox-main.name}/${aws_ecs_service.soasandbox-managed.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [
    aws_appautoscaling_target.target_managed,
  ]
}