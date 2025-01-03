#Update passwords for existing users with one off null resource executions
#this is intended for when restoring from a snapshot in a non-prod environment

resource "random_password" "user_password" {
  for_each         = toset(var.user_passwords_to_reset)
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "user_admin_secret" {
  for_each    = toset(var.user_passwords_to_reset)
  name        = "${var.name}-db-${each.value}-password"
  description = "Password for User on db"
}

resource "aws_secretsmanager_secret_version" "user_secret_version" {
  for_each      = toset(var.user_passwords_to_reset)
  secret_id     = aws_secretsmanager_secret.user_admin_secret[each.value].id
  secret_string = random_password.user_password[each.value].result
}

data "aws_secretsmanager_secret_version" "master_secret" {
  secret_id = module.aurora.cluster_master_user_secret[0].secret_arn
}

resource "null_resource" "reset_passwords" {
  for_each = toset(var.user_passwords_to_reset)

  provisioner "local-exec" {
    environment = {
      DB_PASSWORD   = jsondecode(data.aws_secretsmanager_secret_version.master_secret.secret_string)["password"]
      USER_PASSWORD = aws_secretsmanager_secret_version.user_secret_version[each.value].secret_string
    }

    command = "bash ./modules/aurora/scripts/reset_db_passwords.sh ${module.aurora.cluster_endpoint} ${module.aurora.cluster_master_username} \"$DB_PASSWORD\" ${each.value} \"$USER_PASSWORD\""
  }

  depends_on = [module.aurora]
}
