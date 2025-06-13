resource "kubernetes_secret" "ui_rds" {
  metadata {
    name      = "ui-rds"
    namespace = kubernetes_namespace.ui.metadata[0].name
  }

  type = "Opaque"
  data = {
    username                   = module.ui_rds.db_instance_username
    password                   = random_password.ui_rds.result
    address                    = module.ui_rds.db_instance_address
    port                       = module.ui_rds.db_instance_port
    postgres_connection_string = "postgresql://${module.ui_rds.db_instance_username}:${random_password.ui_rds.result}@${module.ui_rds.db_instance_address}:${module.ui_rds.db_instance_port}/ui"
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
