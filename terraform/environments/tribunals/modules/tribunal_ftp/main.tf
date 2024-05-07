locals {
  app                = var.app_name
  app_url            = var.app_url
  documents_location = var.documents_location
  sftp_host_port     = var.sftp_host_port

  app_container_definition = jsonencode([
    {
      command = [
        "C:\\ServiceMonitor.exe w3svc"
      ],
      entryPoint = [
        "powershell",
        "-Command"
      ],
      name = "${local.app}-container",
      image = "${aws_ecr_repository.app-ecr-repo.repository_url}:latest",
      cpu = 512,
      memory = 1024,
      essential = true,
      portMappings = [
        {
          hostPort = "${local.sftp_host_port}",
          containerPort = 22,
          protocol = "tcp"
        },
        {
          hostPort = 0,
          containerPort = 80,
          protocol = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group" = "${local.app}-ecs-log-group",
          "awslogs-region" = "eu-west-2",
          "awslogs-stream-prefix" = "ecs"
        }
      },
      mountPoints = [
        {
          sourceVolume = "tribunals",
          containerPath = "C:/inetpub/wwwroot/${local.documents_location}"
        }
      ]
    }
  ])
}

####################### ECR #########################################

resource "aws_ecr_repository" "app-ecr-repo" {
  name         = "${local.app}-ecr-repo"
  force_delete = true
}

####################### ECS Task #########################################

module "app_ecs_task" {
  source                    = "../ecs_task"
  app_name                  = local.app
  task_definition_volume    = var.task_definition_volume
  container_definition      = local.app_container_definition
  tags_common               = var.tags
  appscaling_min_capacity   = var.appscaling_min_capacity
  appscaling_max_capacity   = var.appscaling_max_capacity
  ecs_scaling_cpu_threshold = var.ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold = var.ecs_scaling_mem_threshold
  app_count                 = var.app_count
  lb_tg_arn                 = module.ecs_loadbalancer.tribunals_target_group_arn
  server_port               = var.server_port
  lb_listener               = module.ecs_loadbalancer.tribunals_lb_listener
  cluster_id                = var.cluster_id
  cluster_name              = var.cluster_name
  is_ftp_app                = var.is_ftp_app
  sftp_lb_tg_arn            = module.ecs_loadbalancer.sftp_tribunals_target_group_arn
}

####################### Load Balancer #########################################

module "ecs_loadbalancer" {
  source                       = "../ecs_loadbalancer"
  app_name                     = local.app
  tags_common                  = var.tags
  vpc_shared_id                = var.vpc_shared_id
  application_data             = var.application_data
  subnets_shared_public_ids    = var.subnets_shared_public_ids
  aws_acm_certificate_external = var.aws_acm_certificate_external
  is_ftp_app                   = var.is_ftp_app
  sftp_host_port               = var.sftp_host_port
}
