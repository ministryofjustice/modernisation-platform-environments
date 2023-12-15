######################################
# ECS Cluster and Service
######################################
resource "aws_ecs_cluster" "app_ecs_cluster" {
  name = "${local.application_name}-api-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "maat_api_ecs_service" {
  depends_on = [aws_lb_listener.maat_api_alb_http_listener]

  name            = "${local.application_name}-api-ecs-service"
  cluster         = aws_ecs_cluster.app_ecs_cluster.id
  launch_type     = "FARGATE"
  desired_count   = local.application_data.accounts[local.environment].ecs_service_count
  task_definition = aws_ecs_task_definition.task_definition.arn
  health_check_grace_period_seconds = 120

  network_configuration {
    subnets = [
      data.aws_subnets.shared-private.ids[0],
      data.aws_subnets.shared-private.ids[1],
      data.aws_subnets.shared-private.ids[2],
    ]
    security_groups = [aws_security_group.maat_api_ecs_security_group.id]
    assign_public_ip = false
  }
  
  ######## ADD LB DETAILS HERE
  load_balancer {
    container_name   = "${local.application_name}-cd-api"
    container_port   = 8090
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-api-ecs-service"
    }
  )
}

######################################
# ECS TASK DEFINITION
######################################
resource "aws_ecs_task_definition" "TaskDefinition" {
  family                   = "${local.application_name}-api-task-definition"
  cpu                      = var.cNonProd ? 1024 : 1024
  memory                   = var.cNonProd ? 2048 : 3072
  network_mode             = "awsvpc"
  requires_compatibilities = [var.pLaunchType]
  execution_role_arn       = aws_iam_role.ECSTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ECSTaskExecutionRole.arn

  container_definitions = jsonencode([
    {
      name        = var.pAppName
      cpu         = var.cNonProd ? 992 : 992
      essential   = true
      image       = "${var.pECSRepositoryURL}:${var.pDockerImageTag}"
      memory      = var.cNonProd ? 1792 : 2816
      log_configuration = {
        log_driver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.CloudwatchLogsGroup.name
          "awslogs-region"        = var.AWS_Region
          "awslogs-stream-prefix" = "${var.pAppName}-app"
        }
      }
      port_mappings = [
        {
          container_port = 8090
        }
      ]
      secrets = [
        {
          name      = "DATASOURCE_USERNAME"
          value_from = "arn:aws:ssm:${var.AWS_Region}:${var.AWS_AccountId}:parameter/maat-cd-api/DATASOURCE_USERNAME"
        },
        {
          name      = "DATASOURCE_PASSWORD"
          value_from = "arn:aws:ssm:${var.AWS_Region}:${var.AWS_AccountId}:parameter/APP_MAATDB_DBPASSWORD_MLA1"
        },
        # ... (repeat for other secrets)
      ]
      environment = [
        {
          name  = "DATASOURCE_URL"
          value = var.pDatasourceUrl
        },
        # ... (repeat for other environment variables)
      ]
    }
  ])
}


######################################
# ECS Scaling
######################################
resource "aws_appautoscaling_target" "ecs_service_scaling_target" {
  max_capacity = 5
  min_capacity = local.application_data.accounts[local.environment].ecs_service_count
  resource_id          = "service/${aws_ecs_cluster.example.id}/${aws_ecs_service.example.name}"
  role_arn             = aws_iam_role.maat_api_ecs_autoscaling_role.arn
  scalable_dimension   = "ecs:service:DesiredCount"
  service_namespace    = "ecs"
}

resource "aws_appautoscaling_policy" "maat_api_scaling_up_policy" {
  name               = "${local.application_name}-api-scaling-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_service_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service_scaling_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60

    step_adjustment {
      scaling_adjustment        = 1
      metric_interval_lower_bound = 0
    }
  }
}

resource "aws_appautoscaling_policy" "maat_api_scaling_down_policy" {
  name               = "${local.application_name}-api-scaling-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_service_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service_scaling_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60

    step_adjustment {
      scaling_adjustment        = -1
      metric_interval_lower_bound = 0
    }
  }
}

######################################
# CloudWatch Alarms for Scaling
######################################
resource "aws_cloudwatch_metric_alarm" "maat_api_high_cpu_service_alarm" {
  alarm_name          = "${local.application_name}-api-high-cpu-service-alarm"
  alarm_description   = "CPUUtilization exceeding threshold. Triggers scale up"
  actions_enabled     = true
  namespace           = "AWS/ECS" 
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = 70
  unit                = "Percent"
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_appautoscaling_policy.maat_api_scaling_up_policy.arn]
  
  dimensions = {
    ClusterName = aws_ecs_cluster.app_ecs_cluster.name
    ServiceName = aws_ecs_service.maat_api_ecs_service.name
  }
}

resource "aws_cloudwatch_metric_alarm" "maat_api_low_cpu_service_alarm" {
  alarm_name          = "${local.application_name}-api-low-cpu-service-alarm"
  alarm_description   = "CPUUtilization lower than threshold. Triggers scale down"
  actions_enabled     = true
  namespace           = "AWS/ECS" 
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = 20
  unit                = "Percent"
  comparison_operator = "LessThanThreshold"
  alarm_actions       = [aws_appautoscaling_policy.maat_api_scaling_down_policy.arn]
  
  dimensions = {
    ClusterName = aws_ecs_cluster.app_ecs_cluster.name
    ServiceName = aws_ecs_service.maat_api_ecs_service.name
  }
}