resource "random_password" "dashboard_service_secret_key" {
  count = terraform.workspace == "analytical-platform-compute-test" ? 0 : 1

  length  = 32
  special = false
}

resource "random_password" "dashboard_service_rds" {
  count = terraform.workspace == "analytical-platform-compute-test" ? 0 : 1

  length  = 32
  special = false
}
