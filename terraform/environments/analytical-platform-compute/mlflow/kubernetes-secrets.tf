resource "kubernetes_secret" "mlflow_auth_rds" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  metadata {
    name      = "mlflow-auth-rds"
    namespace = kubernetes_namespace.mlflow[0].metadata[0].name
  }

  type = "Opaque"
  data = {
    username                   = module.mlflow_auth_rds[0].db_instance_username
    password                   = random_password.mlflow_auth_rds[0].result
    address                    = module.mlflow_auth_rds[0].db_instance_address
    port                       = module.mlflow_auth_rds[0].db_instance_port
    postgres_connection_string = "postgresql://${module.mlflow_auth_rds[0].db_instance_username}:${random_password.mlflow_auth_rds[0].result}@${module.mlflow_auth_rds[0].db_instance_address}:${module.mlflow_auth_rds[0].db_instance_port}/mlflowauth"
  }
}

resource "kubernetes_secret" "mlflow_rds" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  metadata {
    name      = "mlflow-rds"
    namespace = kubernetes_namespace.mlflow[0].metadata[0].name
  }

  type = "Opaque"
  data = {
    username                   = module.mlflow_rds[0].db_instance_username
    password                   = random_password.mlflow_rds[0].result
    address                    = module.mlflow_rds[0].db_instance_address
    port                       = module.mlflow_rds[0].db_instance_port
    postgres_connection_string = "postgresql://${module.mlflow_rds[0].db_instance_username}:${random_password.mlflow_rds[0].result}@${module.mlflow_rds[0].db_instance_address}:${module.mlflow_rds[0].db_instance_port}/mlflow"
  }
}

resource "kubernetes_secret" "mlflow_admin" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  metadata {
    name      = "mlflow-admin"
    namespace = kubernetes_namespace.mlflow[0].metadata[0].name
  }

  type = "Opaque"
  data = {
    password = random_password.mlflow_admin[0].result
  }
}

resource "kubernetes_secret" "mlflow_flask_server_secret_key" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  metadata {
    name      = "mlflow-flask-server-secret-key"
    namespace = kubernetes_namespace.mlflow[0].metadata[0].name
  }

  type = "Opaque"
  data = {
    secret-key = random_password.mlflow_flask_server_secret_key[0].result
  }
}
