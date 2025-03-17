resource "kubernetes_secret" "mlflow_auth_rds" {
  metadata {
    name      = "mlflow-auth-rds"
    namespace = kubernetes_namespace.mlflow.metadata[0].name
  }

  type = "Opaque"
  data = {
    username                   = data.aws_db_instance.mlflow_auth_rds.master_username
    password                   = data.aws_secretsmanager_secret_version.mlflow_auth_rds.secret_string
    address                    = data.aws_db_instance.mlflow_auth_rds.address
    port                       = data.aws_db_instance.mlflow_auth_rds.db_instance_port
    postgres_connection_string = "postgresql://${data.aws_db_instance.mlflow_auth_rds.master_username}:${data.aws_secretsmanager_secret_version.mlflow_auth_rds.secret_string}@${data.aws_db_instance.mlflow_auth_rds.address}:${data.aws_db_instance.mlflow_auth_rds.db_instance_port}/mlflowauth"
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
    password                   = data.aws_secretsmanager_secret_version.mlflow_rds.secret_string
    address                    = data.aws_db_instance.mlflow_rds.address
    port                       = data.aws_db_instance.mlflow_rds.db_instance_port
    postgres_connection_string = "postgresql://${data.aws_db_instance.mlflow_rds.master_username}:${data.aws_secretsmanager_secret_version.mlflow_rds.secret_string}@${data.aws_db_instance.mlflow_rds.address}:${data.aws_db_instance.mlflow_rds.db_instance_port}/mlflow"
  }
}

resource "kubernetes_secret" "mlflow_admin" {
  metadata {
    name      = "mlflow-admin"
    namespace = kubernetes_namespace.mlflow.metadata[0].name
  }

  type = "Opaque"
  data = {
    password = data.aws_secretsmanager_secret_version.mlflow_admin.secret_string
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
    password                   = data.aws_secretsmanager_secret_version.ui_rds.secret_string
    address                    = data.aws_db_instance.ui_rds.address
    port                       = data.aws_db_instance.ui_rds.db_instance_port
    postgres_connection_string = "postgresql://${data.aws_db_instance.ui_rds.master_username}:${data.aws_secretsmanager_secret_version.ui_rds.secret_string}@${data.aws_db_instance.ui_rds.address}:${data.aws_db_instance.ui_rds.db_instance_port}/ui"
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
    secret_key  = data.aws_secretsmanager_secret_version.ui_app_secrets.secret_string
  }
}
