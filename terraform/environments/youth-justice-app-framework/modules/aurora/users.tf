#Update passwords for existing users with one off null resource executions
#this is intended for when restoring from a snapshot in a non-prod environment

locals {
  user_passwords_to_reset = concat(var.user_passwords_to_reset_rotated, var.user_passwords_to_reset_static)
}

resource "random_password" "user_password" {
  for_each         = toset(local.user_passwords_to_reset)
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "user_admin_secret" {
  #checkov:skip=CKV2_AWS_57:todo add rotation if needed
  for_each    = toset(local.user_passwords_to_reset)
  name        = "${var.name}-db-${each.value}-password"
  description = "Password for User on db"
  kms_key_id  = var.kms_key_id
}

resource "aws_secretsmanager_secret_version" "aurora_rotated_user_version" {
  for_each  = toset(local.user_passwords_to_reset)
  secret_id = aws_secretsmanager_secret.user_admin_secret[each.value].id
  secret_string = jsonencode({
    username            = each.value
    password            = random_password.user_password[each.value].result
    engine              = "postgres"
    host                = module.aurora.cluster_endpoint
    port                = 5432
    dbname              = var.db_name
    dbClusterIdentifier = module.aurora.cluster_id
  })
  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret_rotation" "aurora_rotated_user" {
  for_each            = toset(var.user_passwords_to_reset_rotated)
  secret_id           = aws_secretsmanager_secret.user_admin_secret[each.value].id
  rotation_lambda_arn = aws_lambda_function.rds_secret_rotation.arn
  rotation_rules {
    automatically_after_days = 30 # Adjust as needed
  }
  depends_on = [aws_lambda_permission.allow_secrets_manager]
}

data "aws_secretsmanager_secret_version" "master_secret" {
  secret_id = module.aurora.cluster_master_user_secret[0].secret_arn
}

#resource "null_resource" "reset_passwords" { # doesn't work because we need access to rds from github runner
#  for_each = toset(var.user_passwords_to_reset)

#  provisioner "local-exec" {
#    environment = {
#      DB_PASSWORD   = jsondecode(data.aws_secretsmanager_secret_version.master_secret.secret_string)["password"]
#      USER_PASSWORD = jsondecode(aws_secretsmanager_secret_version.aurora_rotated_user_version[each.value].secret_string)["password"]
#    }

#    command = "bash ./modules/aurora/scripts/reset_db_passwords.sh ${module.aurora.cluster_endpoint} ${module.aurora.cluster_master_username} \"$DB_PASSWORD\" ${each.value} \"$USER_PASSWORD\""
#  }

#run everytime
#  triggers = {
#    always_run = timestamp()
#  }

#  depends_on = [module.aurora]
#}
