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
      NEW_DB_NAME = "lands"
      NEW_USER_NAME = "lands_admin"
      NEW_PASSWORD = random_password.new_password.result
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

 resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.application_name}-${var.environment}-credentials"
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