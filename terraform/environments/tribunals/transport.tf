resource "random_password" "new_password" {
  length  = 16
  special = false //Only printable ASCII characters besides '/', '@', '"', ' ' may be used.
  #override_special = "!#$%&*()-_=+[]{}<>:?" 
}

resource "null_resource" "setup_db" {
  depends_on = [aws_db_instance.rdsdb] #wait for the db to be ready

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "ifconfig -a; chmod +x ./transport/setup-mssql.sh; ./transport/setup-mssql.sh"

    environment = {
      DB_URL = aws_db_instance.rdsdb.address     
      USER_NAME = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)["username"])
      PASSWORD = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)["password"])
      NEW_DB_NAME = "transport"
      NEW_USER_NAME = "transport_app"
      NEW_PASSWORD = random_password.new_password.result
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

 resource "aws_secretsmanager_secret" "db_credentials" {
  #provider = aws.eu-west-1
  name = "tf-tribunals-transport-credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  #provider = "aws.eu-west-1"
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = <<EOF
{
  "username": "transport_app",
  "password": "${random_password.new_password.result}",  
  "host": "${aws_db_instance.rdsdb.address}",  
  "database_name": "transport"
}
EOF
}