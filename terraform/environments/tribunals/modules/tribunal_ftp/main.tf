locals {
  target_group_attachment_port      = var.target_group_attachment_port
  target_group_attachment_port_sftp = var.target_group_attachment_port_sftp
  app                               = var.app_name
  app_url                           = var.app_url
  module_name                       = var.module_name
  documents_location                = var.documents_location
  //Convert the container definition first
  app_container_definition = jsonencode([{
    command : [
      "C:\\ServiceMonitor.exe w3svc"
    ],
    entryPoint : ["powershell", "-Command"],
    name : "${local.app}-container",
    image : "${aws_ecr_repository.app-ecr-repo.repository_url}:latest",
    cpu : 512,
    memory : 1024,
    essential : true,
    portMappings : [
      {
        hostPort : "${local.target_group_attachment_port_sftp}",
        containerPort : 22,
        protocol : "tcp"
      },
      {
        "hostPort" : "${local.target_group_attachment_port}",
        "containerPort" : 80,
        "protocol" : "tcp"
      }
    ],
    logConfiguration : {
      logDriver : "awslogs",
      options : {
        "awslogs-group" : "${local.app}-ecs-log-group",
        "awslogs-region" : "eu-west-2",
        "awslogs-stream-prefix" : "ecs"
      }
    },
    mountPoints : [
      {
        sourceVolume : "tribunals",
        containerPath : "C:/inetpub/wwwroot/${local.documents_location}",
        readOnly : true
      }
    ]
  }])
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
  server_port               = var.server_port
  cluster_id                = var.cluster_id
  cluster_name              = var.cluster_name
  is_ftp_app                = var.is_ftp_app
  lb_tg_arn                 = var.target_group_arns["${local.module_name}"]
  sftp_lb_tg_arn            = var.target_group_arns_sftp["${local.module_name}"]
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
  waf_arn                      = var.waf_arn
  target_group_attachment_port = var.target_group_attachment_port
  app_load_balancer            = var.app_load_balancer
}
