module "dms" {
  source                      = "../dms"
  replication_instance_arn    = var.replication_instance_arn
  replication_task_id         = "transport-migration-task"
  #target_db_instance          = 0
  target_endpoint_id          = "transport-target"
  target_database_name        = "transport"
  target_server_name          = var.rds_url
  target_username             = var.rds_user
  target_password             = var.rds_password
  source_endpoint_id          = "transport-source"
  source_database_name        = "Transport"
  source_server_name          = var.source_db_url
  source_username             = var.source_db_user
  source_password             = var.source_db_password
 
}

############################################################################

module "app_based_resources" {
  source                      = "../../app_based_resources"
  app_name                    = "transport"
  ecs_cluster_name            = "transport"
  db_address                  = var.rds_url
  db_port                     = 1433
  db_username                 = var.rds_user
  db_password                 = var.rds_password
  db_name                     = "transport"
  support_email               = var.support_email
  support_team                = var.support_team
  curserver                   = var.curserver
  client_id                   = var.client_id
  vpc_id                      = var.vpc_id
  moj_ip                      = var.moj_ip
  local_tags                  = var.local_tags
  shared_public_ids           = var.shared_public_ids

}


resource "random_password" "new_password" {
  length  = 16
  special = false 
}

resource "null_resource" "setup_db" {
 
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "ifconfig -a; chmod +x ./setup-mssql.sh; ./setup-mssql.sh"

    environment = {
      DB_URL = var.rds_url   
      USER_NAME = var.rds_user
      PASSWORD = var.rds_password
      NEW_DB_NAME = var.app_db_name
      NEW_USER_NAME = var.app_db_login_name
      NEW_PASSWORD = random_password.new_password.result
      APP_FOLDER = "transport"
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

 resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.application_name}-credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = <<EOF
{
  "username": "${var.app_db_login_name}",
  "password": "${random_password.new_password.result}",  
  "host": "${var.rds_url}",  
  "database_name": "${var.app_db_name}"
}
EOF
}