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
