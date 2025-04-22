locals {
  app_container_definition = jsonencode([{
    command : [
      "C:\\ServiceMonitor.exe w3svc"
    ],
    entryPoint : ["powershell", "-Command"],
    name : "${var.app_name}-container",
    image : "${aws_ecr_repository.app-ecr-repo.repository_url}:latest",
    cpu : 512,
    memory : 1024,
    essential : true,
    portMappings : [
      {
        hostPort : var.target_group_attachment_port_sftp,
        containerPort : 22,
        protocol : "tcp"
      },
      {
        "hostPort" : var.target_group_attachment_port,
        "containerPort" : 80,
        "protocol" : "tcp"
      }
    ],
    logConfiguration : {
      logDriver : "awslogs",
      options : {
        "awslogs-group" : "${var.app_name}-ecs-log-group",
        "awslogs-region" : "eu-west-2",
        "awslogs-stream-prefix" : "ecs"
      }
    },
    mountPoints : [
      {
        sourceVolume : "tribunals",
        containerPath : "C:/inetpub/wwwroot"
      }
    ]
  }])
}

####################### ECR #########################################

resource "aws_ecr_repository" "app-ecr-repo" {
  #checkov:skip=CKV_AWS_136:"Using default AWS encryption for ECR which is sufficient for our needs"
  #checkov:skip=CKV_AWS_51:"Repository needs to be mutable to support latest tag deployments"
  name                 = "${var.app_name}-ecr-repo"
  force_delete         = false
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

####################### ECS Task #########################################

module "app_ecs_task" {
  source                    = "../ecs_task"
  app_name                  = var.app_name
  task_definition_volume    = var.task_definition_volume
  container_definition      = local.app_container_definition
  tags_common               = var.tags
  appscaling_min_capacity   = var.appscaling_min_capacity
  appscaling_max_capacity   = var.appscaling_max_capacity
  ecs_scaling_cpu_threshold = var.ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold = var.ecs_scaling_mem_threshold
  app_count                 = var.app_count
  server_port               = var.server_port
  cluster_id                = var.cluster_id
  cluster_name              = var.cluster_name
  is_ftp_app                = var.is_ftp_app
  lb_tg_arn                 = var.target_group_arns[var.module_name]
  sftp_lb_tg_arn            = var.target_group_arns_sftp[var.module_name]
}
