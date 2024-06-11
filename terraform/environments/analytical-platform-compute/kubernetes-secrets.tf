resource "kubernetes_secret" "mlflow_auth_rds" {
  metadata {
    name      = "mlflow-auth-rds"
    namespace = kubernetes_namespace.mlflow.metadata[0].name
  }

  type = "Opaque"
  data = {
    username                   = module.mlflow_auth_rds.db_instance_username
    password                   = random_password.mlflow_auth_rds.result
    postgres_connection_string = "postgresql://${module.mlflow_auth_rds.db_instance_username}:${random_password.mlflow_auth_rds.result}@${module.mlflow_auth_rds.db_instance_address}:${module.mlflow_auth_rds.db_instance_port}/mlflowauth"
  }
}

resource "kubernetes_secret" "mlflow_rds" {
  metadata {
    name      = "mlflow-rds"
    namespace = kubernetes_namespace.mlflow.metadata[0].name
  }

  type = "Opaque"
  data = {
    username                   = module.mlflow_rds.db_instance_username
    password                   = random_password.mlflow_rds.result
    postgres_connection_string = "postgresql://${module.mlflow_rds.db_instance_username}:${random_password.mlflow_rds.result}@${module.mlflow_rds.db_instance_address}:${module.mlflow_rds.db_instance_port}/mlflow"
  }
}
