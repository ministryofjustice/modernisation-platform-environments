# #### This file can be used to store secrets specific to the member account ####

resource "random_password" "password" {
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = false
}

resource "aws_secretsmanager_secret" "resource_rds_secret" {
  name                    = "${local.application_data.accounts[local.environment].db_identifier}_credentials"
  recovery_window_in_days = 0
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

//source db secret definition, will be filled manually
resource "aws_secretsmanager_secret" "resource_source_db_secret" {
  name                    = "tribunals-source-credentials-db"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "resource_source_db_secret_current" {
  secret_id     = aws_secretsmanager_secret.resource_source_db_secret.id
  secret_string = <<EOF
  {
    "username": "",
    "password": "",
    "engine": "sqlserver",
    "host": "${local.application_data.accounts[local.environment].dms_source_db}",
    "port": 1433,
    "dbname": "master",
    "dms_source_account_access_key": "",
    "dms_source_account_secret_key": "",
    "ec2-instance-id": ""
  }
  EOF
}
// retrieve secrets for the source database on mojdsd account
data "aws_secretsmanager_secret" "source_db_secret" {
  depends_on = [aws_secretsmanager_secret_version.resource_source_db_secret_current]
  arn        = aws_secretsmanager_secret_version.resource_source_db_secret_current.arn
}

data "aws_secretsmanager_secret_version" "source_db_secret_current" {
  depends_on = [aws_secretsmanager_secret_version.resource_source_db_secret_current]
  secret_id  = data.aws_secretsmanager_secret.source_db_secret.id
}

//admin site credentials secret definition, will be filled manually
//employment appeals (eat) uses a different encryption method for the password
resource "aws_secretsmanager_secret" "tribunals_admin_site_credentials" {
  name                    = "tribunals-admin-site-credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "tribunals_admin_site_credentials_current" {
  secret_id     = aws_secretsmanager_secret.tribunals_admin_site_credentials.id
  secret_string = <<EOF
  {
    "admin_username": "",
    "admin_password": "",
    "admin_password_eat": "",
    "admin_password_unencrypted": ""
  }
  EOF
}

data "aws_secretsmanager_secret" "tribunals_admin_site_secret" {
  depends_on = [aws_secretsmanager_secret_version.tribunals_admin_site_credentials_current]
  arn        = aws_secretsmanager_secret_version.tribunals_admin_site_credentials_current.arn
}

data "aws_secretsmanager_secret_version" "tribunals_admin_site_credentials_secret_current" {
  depends_on = [aws_secretsmanager_secret_version.tribunals_admin_site_credentials_current]
  secret_id  = data.aws_secretsmanager_secret.tribunals_admin_site_secret.id
}

resource "aws_secretsmanager_secret" "sftp_private_key" {
  name                    = "private-key-sftp-upload"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "sftp_private_key" {
  secret_id     = aws_secretsmanager_secret.sftp_private_key.id
  secret_string = <<EOF
  {
    "sftp_private_key": ""
  }
  EOF
}
