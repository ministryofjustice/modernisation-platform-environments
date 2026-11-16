resource "random_password" "app_secrets" {
  length  = 32
  special = false
}

resource "random_password" "app_rds" {
  length  = 32
  special = false
}
