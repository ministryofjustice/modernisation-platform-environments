locals {
  schedules = var.disable_overnight_scheduler ? {} : {
    night = {
      min_size         = 0
      max_size         = 0
      desired_capacity = 0
      recurrence       = var.overnight_cron_schedule
      time_zone        = "Etc/GMT"
    }

    morning = {
      min_size         = var.ec2_min_size
      max_size         = var.ec2_max_size
      desired_capacity = var.ec2_desired_capacity
      recurrence       = var.morning_cron_schedule
      time_zone        = "Etc/GMT"
    }
  }

  default_environment_variables = [
    {
      "name" : "DD_JMXFETCH_ENABLED",
      "value" : "true"
    },
    {
      "name" : "DD_VERSION",
      "value" : "1.0.116"
    },
    {
      "name" : "DD_LOGS_INJECTION",
      "value" : "true"
    },
    {
      "name" : "DD_PROFILING_ENABLED",
      "value" : "true"
    }
  ]

  default_mountpoints = [
    {
      sourceVolume : var.project_name,
      containerPath : "/var/www/${var.project_name}",
      readOnly : false
    },
    {
      sourceVolume : "tmp",
      containerPath : "/tmp",
      readOnly : false
    }
  ]

  default_volumes = [
    {
      "name" : "yjaf",
      "host" : {}
    },
    {
      "name" : "tmp",
      "host" : {}
    }
  ]

  common_datadog_rules = [
    {
      from_port   = 8126
      to_port     = 8126
      protocol    = "tcp"
      self        = true
      description = "Datadog from ecs services"
    },
    {
      from_port   = 8125
      to_port     = 8125
      protocol    = "udp"
      self        = true
      description = "Datadog from ecs services"
    }
  ]

  ecs_common_security_group_ingress = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      self        = true
      description = "ECS service to ECS service communication"
    },
    {
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      description     = "ELB to ECS service communication"
      security_groups = [var.internal_alb_security_group_id]
    },
    {
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      description     = "EC2 to ECS service communication"
      security_groups = [module.autoscaling_sg.security_group_id]
    }
  ]

  cloudfront_ingress = [
    {
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      security_groups = [var.external_alb_security_group_id]
      description     = "External cloudfront alb to ECS service communication"
    }
  ]

  # Concatenate the lists here because I can't do it in the resource block
  combined_ingress_rules_external = concat(
    local.ecs_common_security_group_ingress,
    local.cloudfront_ingress,
    local.common_datadog_rules,
    var.additional_ecs_common_security_group_ingress
  )

  # Concatenate the lists
  combined_ingress_rules_internal = concat(
    local.ecs_common_security_group_ingress,
    local.common_datadog_rules,
    var.additional_ecs_common_security_group_ingress
  )

  autoscaling_policies = {
    "cpu" : {
      "policy_type" : "TargetTrackingScaling",
      "target_tracking_scaling_policy_configuration" : {
        "predefined_metric_specification" : {
          "predefined_metric_type" : "ECSServiceAverageCPUUtilization"
        },
        "target_value" : 90.0
      }
    },
    "memory" : {
      "policy_type" : "TargetTrackingScaling",
      "target_tracking_scaling_policy_configuration" : {
        "predefined_metric_specification" : {
          "predefined_metric_type" : "ECSServiceAverageMemoryUtilization"
        },
        "target_value" : 90.0
      }
    }
  }
}

