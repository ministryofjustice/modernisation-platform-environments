resource "aws_appautoscaling_target" "ecs_service" {
  count               = local.is-development ? 0 : 1
  service_namespace  = "ecs"
  resource_id        = "service/dacp_cluster/dacp"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 2
  max_capacity       = 4
}

resource "aws_appautoscaling_policy" "scale_up_amber" {
  count                  = local.is-development ? 0 : 1
  name                   = "scale-up-amber"
  service_namespace      = "ecs"
  resource_id            = aws_appautoscaling_target.ecs_service[0].resource_id
  scalable_dimension     = "ecs:service:DesiredCount"
  policy_type            = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120

    step_adjustment {
      scaling_adjustment    = 1
      metric_interval_lower_bound = 0
    }
    step_adjustment {
      scaling_adjustment    = 1
      metric_interval_lower_bound = 2000
    }
  }
}

resource "aws_appautoscaling_policy" "scale_down_amber" {
  count                  = local.is-development ? 0 : 1
  name                   = "scale-down-amber"
  service_namespace      = "ecs"
  resource_id            = aws_appautoscaling_target.ecs_service[0].resource_id
  scalable_dimension     = "ecs:service:DesiredCount"
  policy_type            = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120

    step_adjustment {
      scaling_adjustment    = -1
      metric_interval_upper_bound = 0
    }
    step_adjustment {
      scaling_adjustment    = -1
      metric_interval_upper_bound = -2000
    }
  }
}