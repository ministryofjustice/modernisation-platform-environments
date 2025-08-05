resource "aws_appautoscaling_target" "ecs_service" {
  service_namespace  = "ecs"
  resource_id        = "service/dacp_cluster/dacp-win2022"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 2
  max_capacity       = 4

  # Suspend scaling during deployment
  suspended_state {
    dynamic_scaling_in_suspended  = true
    dynamic_scaling_out_suspended = true
    scheduled_scaling_suspended   = true
  }
}

resource "aws_appautoscaling_policy" "scale_up_amber" {
  name               = "scale-up-amber"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = "ecs:service:DesiredCount"
  policy_type        = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown        = 120

    #Scale up if memory exceeds the threshold of 2500 (and stay at this level for a max of 2000 MB)
    step_adjustment {
      scaling_adjustment          = 1
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 1500
    }
    #Scale up one more instance if memory exceeds the 2500 threshold by 2000 or more
    step_adjustment {
      scaling_adjustment          = 1
      metric_interval_lower_bound = 1500
    }
  }
}

resource "aws_appautoscaling_policy" "scale_down_amber" {
  name               = "scale-down-amber"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = "ecs:service:DesiredCount"
  policy_type        = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown        = 120

    #Scale down 1 instance if memory drops back to within 2000 of the original threshold (and stay there until it hits the original threshold)
    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_lower_bound = -1500
      metric_interval_upper_bound = 0
    }
    #Scale down the final instance if memory drops back to the orginal threshold of 2500 or anything below
    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_lower_bound = null
      metric_interval_upper_bound = -1500
    }
  }
}