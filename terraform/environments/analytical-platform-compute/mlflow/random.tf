resource "random_password" "mlflow_auth_rds" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  length  = 32
  special = false
}

resource "random_password" "mlflow_rds" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  length  = 32
  special = false
}

resource "random_password" "mlflow_admin" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  length  = 32
  special = false
}

resource "random_password" "mlflow_flask_server_secret_key" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  length  = 32
  special = false
}
