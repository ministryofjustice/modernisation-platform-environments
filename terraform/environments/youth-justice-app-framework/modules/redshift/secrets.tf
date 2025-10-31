resource "aws_secretsmanager_secret" "user_admin" {
  #checkov:skip=CKV2_AWS_57: [TODO] Consider adding rotation for the Redshift admin user password.

  name        = "${var.project_name}/${var.environment}/redshift-serverless/"
  description = "Access to the YJB Services Redshift Serverless "
  kms_key_id  = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "user_admin" {
  secret_id = aws_secretsmanager_secret.user_admin.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.user_admin_password.result


  })
}

resource "random_password" "user_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "returns" {
  #checkov:skip=CKV2_AWS_57: [TODO] Consider adding rotation for the Redshift admin user password.

  name        = "${var.project_name}/${var.environment}/returns-microservice/redshift-serverless/"
  description = "Access to Redshift Serverless for the Returns Microservice"
  kms_key_id  = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "returns" {
  secret_id = aws_secretsmanager_secret.returns.id
  secret_string = jsonencode({
    username = "microservice_returns"
    password = "changeme"
    hostname = aws_redshiftserverless_workgroup.default.endpoint[0].address
    port     = aws_redshiftserverless_workgroup.default.endpoint[0].port
    database = "yjb_returns"
    url      = "jdbc:redshift://${aws_redshiftserverless_workgroup.default.endpoint[0].address}:${aws_redshiftserverless_workgroup.default.endpoint[0].port}/yjb_returns;TCPKeepAlice=FALSE"
  })
}

resource "aws_secretsmanager_secret" "yjb_publish" {
  #checkov:skip=CKV2_AWS_57: [TODO] Consider adding rotation for the Redshift admin user password.

  name        = "${var.project_name}/${var.environment}/yjb_publish/redshift-serverless"
  description = "Access to Redshift Serverless for Quicksite data sources"
  kms_key_id  = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "yjb_publish" {
  secret_id = aws_secretsmanager_secret.yjb_publish.id
  secret_string = jsonencode({
    username = "yjb_publish"
    password = "changeme"
    hostname = aws_redshiftserverless_workgroup.default.endpoint[0].address
    port     = aws_redshiftserverless_workgroup.default.endpoint[0].port
    database = "yjb_returns"
    url      = "jdbc:redshift://${aws_redshiftserverless_workgroup.default.endpoint[0].address}:${aws_redshiftserverless_workgroup.default.endpoint[0].port}/yjb_returns;TCPKeepAlive=FALSE"
  })
}

resource "aws_secretsmanager_secret" "yjb_schedular" {
  #checkov:skip=CKV2_AWS_57: [TODO] Consider adding rotation for the Redshift admin user password.

  name        = "${var.project_name}/${var.environment}/yjb_schedular/redshift-serverless"
  description = "Access to Redshift Serverless for Quicksite data sources"
  kms_key_id  = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "yjb_schedular" {
  secret_id = aws_secretsmanager_secret.yjb_schedular.id
  secret_string = jsonencode({
    username = "yjb_schedular"
    password = "changeme"
    hostname = aws_redshiftserverless_workgroup.default.endpoint[0].address
    port     = aws_redshiftserverless_workgroup.default.endpoint[0].port
    database = "yjb_returns"
    url      = "jdbc:redshift://${aws_redshiftserverless_workgroup.default.endpoint[0].address}:${aws_redshiftserverless_workgroup.default.endpoint[0].port}/yjb_returns;TCPKeepAlive=FALSE"
  })
}