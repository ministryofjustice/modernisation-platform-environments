locals {
  app_container_definition = jsonencode([{
    command : [
      "New-Item -Path C:\\inetpub\\wwwroot\\index.html -Type file -Value '<html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p>'; C:\\ServiceMonitor.exe w3svc"
    ],
    entryPoint : ["powershell", "-Command"],
    name : "${var.app_name}-container",
    image : "${aws_ecr_repository.app-ecr-repo.repository_url}:latest",
    cpu : 512,
    memory : 1024,
    essential : true,
    portMappings : [
      {
        hostPort : var.target_group_attachment_port,
        containerPort : 80,
        protocol : "tcp"
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
        containerPath : "C:/inetpub/wwwroot/${var.documents_location}"
      }
    ],
    environment : [
      {
        name : "supportEmail",
        value : var.support_email
      },
      {
        name : "supportTeam",
        value : var.support_team
      },
      {
        name : "CurServer",
        value : var.curserver
      },
      {
        name : "RDS_PASSWORD",
        value : var.app_rds_password
      }
    ]
  }])
}

resource "aws_secretsmanager_secret" "app_db_credentials" {
  #checkov:skip=CKV_AWS_149:"Using default AWS encryption for Secrets Manager which is sufficient for our needs"
  #checkov:skip=CKV2_AWS_57:"Automatic rotation not required for this application's DB credentials"
  name                    = "${var.app_name}-credentials-db-2"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app_db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.app_db_credentials.id
  secret_string = <<EOF
{
  "username": "${var.app_db_login_name}",
  "password": "${var.new_db_password}",
  "host": "${var.app_rds_url}",
  "database_name": "${var.app_db_name}"
}
EOF
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
  sftp_lb_tg_arn            = ""
}
