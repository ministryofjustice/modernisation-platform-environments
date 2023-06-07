resource "random_password" "new_password" {
  length  = 16
  special = false 
}

resource "null_resource" "setup_db" {
  depends_on = [aws_db_instance.rdsdb] #wait for the db to be ready

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "ifconfig -a; chmod +x ./setup-mssql.sh; ./setup-mssql.sh"

    environment = {
      DB_URL = aws_db_instance.rdsdb.address      
      USER_NAME = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"])
      PASSWORD = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"])
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
  "host": "${data.aws_db_instance.database.address}",  
  "database_name": "${var.app_db_name}"
}
EOF
}