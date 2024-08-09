locals {
  target_group_attachment_port = var.target_group_attachment_port
  app                          = var.app_name
  app_url                      = var.app_url
  module_name                  = var.module_name
  sql_migration_path           = var.sql_migration_path
  app_db_name                  = var.app_db_name
  app_db_login_name            = var.app_db_login_name
  app_source_db_name           = var.app_source_db_name
  app_rds_url                  = var.app_rds_url
  app_rds_user                 = var.app_rds_user
  app_rds_port                 = var.app_rds_port
  app_rds_password             = var.app_rds_password
  app_source_db_url            = var.app_source_db_url
  app_source_db_user           = var.app_source_db_user
  app_source_db_password       = var.app_source_db_password
  documents_location           = var.documents_location
  app_container_definition = jsonencode([{
    command : [
      "New-Item -Path C:\\inetpub\\wwwroot\\index.html -Type file -Value '<html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p>'; C:\\ServiceMonitor.exe w3svc"
    ],
    entryPoint : ["powershell", "-Command"],
    name : "${local.app}-container",
    image : "${aws_ecr_repository.app-ecr-repo.repository_url}:latest",
    cpu : 512,
    memory : 1024,
    essential : true,
    portMappings : [
      {
        hostPort : "${local.target_group_attachment_port}",
        containerPort : 80,
        protocol : "tcp"
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
        containerPath : "C:/inetpub/wwwroot/${local.documents_location}"
      }
    ],
    environment : [
      {
        name : "supportEmail",
        value : "${var.application_data.support_email}"
      },
      {
        name : "supportTeam",
        value : "${var.application_data.support_team}"
      },
      {
        name : "CurServer",
        value : "${var.application_data.curserver}"
      },
      {
        name : "RDS_PASSWORD",
        value : "${local.app_rds_password}"
      }
    ]
  }])
  app_ec2_ingress_rules = {
    "cluster_ec2_lb_ingress_2" = {
      description     = "Cluster EC2 ingress rule 2"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }
  app_ec2_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description     = "Cluster EC2 loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }
}

######################## DMS #############################################

module "app_dms" {
  source                   = "../dms"
  replication_instance_arn = var.dms_instance_arn
  replication_task_id      = "${local.app}-migration-task"
  #target_db_instance          = 0
  target_endpoint_id   = "${local.app}-target"
  target_database_name = local.app_db_name
  target_server_name   = local.app_rds_url
  target_username      = local.app_rds_user
  target_password      = local.app_rds_password
  source_endpoint_id   = "${local.app}-source"
  source_database_name = local.app_source_db_name
  source_server_name   = local.app_source_db_url
  source_username      = local.app_source_db_user
  source_password      = local.app_source_db_password

}

############################################################################

resource "aws_secretsmanager_secret" "app_db_credentials" {
  name                    = "${local.app}-credentials-db-2"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app_db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.app_db_credentials.id
  secret_string = <<EOF
{
  "username": "${local.app_db_login_name}",
  "password": "${var.new_db_password}",
  "host": "${local.app_rds_url}",
  "database_name": "${local.app_db_name}"
}
EOF
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
  sftp_lb_tg_arn            = ""
}
