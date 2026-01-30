module "ecs_service_datadog_agent" {
  #checkov:skip=CKV_TF_1: todo
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "6.9.0"

  name        = "datadog-agent"
  cluster_arn = var.ecs_cluster_arn

  # Task Definition
  requires_compatibilities           = ["EC2"]
  launch_type                        = "EC2"
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 100
  health_check_grace_period_seconds  = 60
  scheduling_strategy                = "DAEMON" # Run one task per EC2 instance


  cpu                            = var.agent_datadog_cpu    #128
  memory                         = var.agent_datadog_memory #512
  ignore_task_definition_changes = false
  create_security_group          = false
  create_tasks_iam_role          = false
  create_task_exec_iam_role      = false

  network_mode           = "bridge"
  task_exec_iam_role_arn = var.ecs_task_exec_iam_role_arn
  tags                   = var.tags

  # Add the Datadog Agent as a container to the ECS service
  container_definitions = {
    datadog = {
      name      = "datadog-agent"
      image     = "datadog/agent:latest-jmx"
      cpu       = var.agent_datadog_container_cpu    #100
      memory    = var.agent_datadog_container_memory #512
      essential = true

      readonly_root_filesystem = false
      privileged               = true
      secrets = [
        {
          name      = "DD_API_KEY"
          valueFrom = aws_secretsmanager_secret_version.plain_datadog_api.arn
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
          name  = "DD_ECS_FARGATE"
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
          "name" : "DD_LOGS_ENABLED",
          "value" : "true"
        },
        {
          "name" : "DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL",
          "value" : "true"
        },
        {
          "name" : "DD_DOGSTATSD_PORT",
          "value" : "8125"
        },
        {
          "name" : "DD_DOGSTATSD_NON_LOCAL_TRAFFIC",
          "value" : "true"
        },
        {
          "name" : "DD_JMX_ENABLED",
          "value" : "true"
        },
        {
          "name" : "DD_JMXFETCH_CONTAINER_COLLECT_ALL",
          "value" : "true"
        },
        {
          "name" : "DD_JMXFETCH_PORT",
          "value" : "5555"
        },
        {
          "name" : "DD_SYSTEM_PROBE_ENABLED",
          "value" : "false"
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
        },
        {
          "name" : "DD_ECS_TASK_COLLECTION_ENABLED",
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
      "host_path" : "/var/run/docker.sock"
    },
    {
      "name" : "proc",
      "host_path" : "/proc/"
    },
    {
      "name" : "cgroup",
      "host_path" : "/sys/fs/cgroup/"
    }
  ]
}
