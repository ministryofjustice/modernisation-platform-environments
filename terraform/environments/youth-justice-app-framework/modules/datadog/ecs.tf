module "ecs_service_datadog_agent" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.2"

  name        = "datadog-agent"
  cluster_arn = var.ecs_cluster_arn

  # Task Definition
  requires_compatibilities           = ["EC2"]
  launch_type                        = "EC2"
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 100
  health_check_grace_period_seconds  = 60
  scheduling_strategy                = "DAEMON" # Run one task per EC2 instance


  # Add the Datadog Agent as a container to the ECS service
  container_definitions = {
    datadog = {
      name      = "datadog-agent"
      image     = "datadog/agent:latest-jmx"
      cpu       = 100
      memory    = 512
      essential = false

      readonly_root_filesystem = false

      secrets = [
        {
          name      = "DD_API_KEY"
          valueFrom = aws_secretsmanager_secret_version.datadog_api.arn
        }
      ]
      port_mappings = [
        {
          name          = "dogstatsd"
          containerPort = 8125
          hostPort      = 8125
          protocol      = "udp"
        },
        {
          name          = "trace-agent"
          containerPort = 8126
          hostPort      = 8126
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ECS_FARGATE"
          value = "false"
        },
        {
          "name" : "DD_SITE",
          "value" : "datadoghq.eu"
        },
        {
          "name" : "DD_APM_ENABLED",
          "value" : var.enable_datadog_agent_apm ? "true" : "false"
        },
        {
          "name" : "DD_SYSTEM_PROBE_ENABLED",
          "value" : "true"
        },
        {
          "name" : "DD_TAGS",
          "value" : "project:yjaf env:preproduction moj:true"
        },
        {
          "name" : "DD_DOGSTATSD_TAGS",
          "value" : "preproduction"
        },
        {
          "name" : "DD_APM_NON_LOCAL_TRAFFIC",
          "value" : var.enable_datadog_agent_apm ? "true" : "false"
        },
        {
          "name" : "DD_DOGSTATSD_NON_LOCAL_TRAFFIC",
          "value" : "true"
        }
      ]

      mount_points = [
        {
          "sourceVolume" : "docker_sock",
          "containerPath" : "/var/run/docker.sock",
          "readOnly" : true
        },
        {
          "sourceVolume" : "proc",
          "containerPath" : "/host/proc/",
          "readOnly" : true
        },
        {
          "sourceVolume" : "cgroup",
          "containerPath" : "/host/sys/fs/cgroup",
          "readOnly" : null
        }
      ]
    }
  }

  # Mount volume for Docker socket
  volume = [
    {
      "name" : "docker_sock",
      "host" : {
        "sourcePath" : "/var/run/docker.sock"
      }
    },
    {
      "name" : "proc",
      "host" : {
        "sourcePath" : "/proc/"
      }
    },
    {
      "name" : "cgroup",
      "host" : {
        "sourcePath" : "/sys/fs/cgroup/"
      }
    }
  ]

  ignore_task_definition_changes = true
  create_security_group          = false
  create_tasks_iam_role          = false
  create_task_exec_iam_role      = false

  subnet_ids             = var.ecs_subnet_ids
  security_group_ids     = [var.ecs_security_group_id]
  tasks_iam_role_name    = var.ecs_task_iam_role_name
  tasks_iam_role_arn     = var.ecs_task_iam_role_arn
  task_exec_iam_role_arn = var.ecs_task_exec_iam_role_arn

  tags = var.tags
}
