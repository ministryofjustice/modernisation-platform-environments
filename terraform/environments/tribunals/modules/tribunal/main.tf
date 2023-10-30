locals {
  app = var.app_name
  app_url = var.app_url
  sql_migration_path = var.sql_migration_path
  app_db_name = var.app_db_name
  app_db_login_name = var.app_db_login_name
  app_source_db_name = var.app_source_db_name
  app_rds_url               = "${var.app_rds_url}"      
  app_rds_user              = "${var.app_rds_user}"
  app_rds_port              = var.app_rds_port
  app_rds_password          = "${var.app_rds_password}"
  app_source_db_url         = "${var.app_source_db_url}"
  app_source_db_user        = "${var.app_source_db_user}"
  app_source_db_password    = "${var.app_source_db_password}"
  app_user_data = base64encode(templatefile("user_data.sh", {
    cluster_name = "${local.app}_app_cluster"
  }))
  app_task_definition = templatefile("task_definition.json", {
    app_name            = "${local.app}"
    #ecr_url             = "mcr.microsoft.com/dotnet/framework/aspnet:4.8"
    #docker_image_tag    = "latest" 
    #sentry_env          = local.environment
    awslogs-group       = "${local.app}-ecs-log-group"
    supportEmail        = "${var.application_data.support_email}"
    supportTeam         = "${var.application_data.support_team}"
    CurServer           = "${var.application_data.curserver}"

  })
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
  source                      = "../dms"
  replication_instance_arn    = var.dms_instance_arn
  replication_task_id         = "${local.app}-migration-task"
  #target_db_instance          = 0
  target_endpoint_id          = "${local.app}-target"
  target_database_name        = local.app_db_name
  target_server_name          = local.app_rds_url
  target_username             = local.app_rds_user
  target_password             = local.app_rds_password
  source_endpoint_id          = "${local.app}-source"
  source_database_name        = local.app_source_db_name
  source_server_name          = local.app_source_db_url
  source_username             = local.app_source_db_user
  source_password             = local.app_source_db_password
 
}

############################################################################

resource "random_password" "app_new_password" {
  length  = 16
  special = false 
}

resource "null_resource" "app_setup_db" {
 
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "ifconfig -a; chmod +x ./setup-mssql.sh; ./setup-mssql.sh"

    environment = {
      DB_URL = local.app_rds_url   
      USER_NAME = local.app_rds_user
      PASSWORD = local.app_rds_password
      NEW_DB_NAME = local.app_db_name
      NEW_USER_NAME = local.app_db_login_name
      NEW_PASSWORD = random_password.app_new_password.result
      APP_FOLDER = local.sql_migration_path
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "aws_secretsmanager_secret" "app_db_credentials" {
  name = "${local.app}-db-credentials-2"
}

resource "aws_secretsmanager_secret_version" "app_db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.app_db_credentials.id
  secret_string = <<EOF
{
  "username": "${local.app_db_login_name}",
  "password": "${random_password.app_new_password.result}",  
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

####################### ECS Task#########################################

module "app_ecs_task" {
  source                      = "../ecs_task"
  app_name                    = local.app
  task_definition_volume      = var.task_definition_volume
  task_definition             = local.app_task_definition
  tags_common                 = var.tags
  appscaling_min_capacity     = var.appscaling_min_capacity
  appscaling_max_capacity     = var.appscaling_max_capacity
  ecs_scaling_cpu_threshold   = var.ecs_scaling_cpu_threshold
  ecs_scaling_mem_threshold   = var.ecs_scaling_mem_threshold
  app_count                   = var.app_count
  lb_tg_arn                   = var.lb_tg_arn
  server_port                 = var.server_port
  lb_listener                 = var.lb_listener
  cluster_id                  = var.cluster_id
  cluster_name                = var.cluster_name
}

