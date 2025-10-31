resource "random_password" "mlflow_auth_rds" {
  length  = 32
  special = false
}

resource "random_password" "mlflow_rds" {
  length  = 32
  special = false
}

resource "random_password" "mlflow_admin" {
  length  = 32
  special = false
}

resource "random_password" "mlflow_flask_server_secret_key" {
  length  = 32
  special = false
}
