resource "random_password" "dashboard_service_secret_key" {
  count = terraform.workspace == "data-platform-test" ? 0 : 1

  length  = 32
  special = false
}

resource "random_password" "dashboard_service_rds" {
  count = terraform.workspace == "data-platform-test" ? 0 : 1

  length  = 32
  special = false
}
