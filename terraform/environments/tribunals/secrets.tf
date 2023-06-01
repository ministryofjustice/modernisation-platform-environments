#### This file can be used to store secrets specific to the member account ####

resource "random_password" "password" {
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = false
}

resource "aws_secretsmanager_secret" "resource_rds_secret" {
  name = "${local.application_data.accounts[local.environment].identifier}-credentials"
}

resource "aws_secretsmanager_secret_version" "resource_rds_secret_current" {
  secret_id     = aws_secretsmanager_secret.resource_rds_secret.id
  secret_string = <<EOF
{
  "username": "${aws_db_instance.rdsdb.username}",
  "password": "${aws_db_instance.rdsdb.password}",
  "engine": "${aws_db_instance.rdsdb.engine}",
  "host": "${aws_db_instance.rdsdb.address}",
  "port": ${aws_db_instance.rdsdb.port},
  "dbClusterIdentifier": "${aws_db_instance.rdsdb.ca_cert_identifier}",
  "database_name": "master"
}
EOF
}

data "aws_secretsmanager_secret" "data_rds_secret" {
  depends_on = [aws_secretsmanager_secret_version.resource_rds_secret_current]
  arn        = aws_secretsmanager_secret_version.resource_rds_secret_current.arn
}

data "aws_secretsmanager_secret_version" "data_rds_secret_current" {
  depends_on = [aws_secretsmanager_secret_version.resource_rds_secret_current]
  secret_id  = data.aws_secretsmanager_secret.data_rds_secret.id
}
