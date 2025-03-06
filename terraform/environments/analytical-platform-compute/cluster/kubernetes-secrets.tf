resource "kubernetes_secret" "mlflow_auth_rds" {
  metadata {
    name      = "mlflow-auth-rds"
    namespace = kubernetes_namespace.mlflow.metadata[0].name
  }

  type = "Opaque"
  data = {
    username                   = data.aws_db_instance.mlflow_auth_rds.master_username
    password                   = random_password.mlflow_auth_rds.result
    address                    = data.aws_db_instance.mlflow_auth_rds.address
    port                       = data.aws_db_instance.mlflow_auth_rds.db_instance_port
    postgres_connection_string = "postgresql://${data.aws_db_instance.mlflow_auth_rds.master_username}:${random_password.mlflow_auth_rds.result}@${data.aws_db_instance.mlflow_auth_rds.address}:${data.aws_db_instance.mlflow_auth_rds.db_instance_port}/mlflowauth"
  }
}

resource "kubernetes_secret" "mlflow_rds" {
  metadata {
    name      = "mlflow-rds"
    namespace = kubernetes_namespace.mlflow.metadata[0].name
  }

  type = "Opaque"
  data = {
    username                   = data.aws_db_instance.mlflow_rds.master_username
    password                   = random_password.mlflow_rds.result
    address                    = data.aws_db_instance.mlflow_rds.address
    port                       = data.aws_db_instance.mlflow_rds.db_instance_port
    postgres_connection_string = "postgresql://${data.aws_db_instance.mlflow_rds.master_username}:${random_password.mlflow_rds.result}@${data.aws_db_instance.mlflow_rds.address}:${data.aws_db_instance.mlflow_rds.db_instance_port}/mlflow"
  }
}

resource "kubernetes_secret" "mlflow_admin" {
  metadata {
    name      = "mlflow-admin"
    namespace = kubernetes_namespace.mlflow.metadata[0].name
  }

  type = "Opaque"
  data = {
    password = random_password.mlflow_admin.result
  }
}

resource "kubernetes_secret" "ui_rds" {
  metadata {
    name      = "ui-rds"
    namespace = kubernetes_namespace.ui.metadata[0].name
  }

  type = "Opaque"
  data = {
    username                   = data.aws_db_instance.ui_rds.master_username
    password                   = random_password.ui_rds.result
    address                    = data.aws_db_instance.ui_rds.address
    port                       = data.aws_db_instance.ui_rds.db_instance_port
    postgres_connection_string = "postgresql://${data.aws_db_instance.ui_rds.master_username}:${random_password.ui_rds.result}@${data.aws_db_instance.ui_rds.address}:${data.aws_db_instance.ui_rds.db_instance_port}/ui"
  }
}

resource "kubernetes_secret" "ui_app_secrets" {
  metadata {
    name      = "ui-app-secrets"
    namespace = kubernetes_namespace.ui.metadata[0].name
  }

  type = "Opaque"
  data = {
    environment = local.environment
    secret_key  = random_password.ui_app_secrets.result
  }
}
