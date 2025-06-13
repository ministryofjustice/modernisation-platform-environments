resource "random_password" "ui_rds" {
  length  = 32
  special = false
}

resource "random_password" "ui_app_secrets" {
  length  = 32
  special = false
}
