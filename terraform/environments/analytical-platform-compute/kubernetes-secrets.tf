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

resource "kubernetes_secret" "dashboard_service_rds" {
  count = terraform.workspace == "analytical-platform-compute-test" ? 0 : 1

  metadata {
    name      = "dashboard-service-rds"
    namespace = kubernetes_namespace.dashboard_service[0].metadata[0].name
  }

  type = "Opaque"
  data = {
    username                   = module.dashboard_service_rds[0].db_instance_username
    password                   = random_password.dashboard_service_rds[0].result
    address                    = module.dashboard_service_rds[0].db_instance_address
    port                       = module.dashboard_service_rds[0].db_instance_port
    postgres_connection_string = "postgresql://${module.dashboard_service_rds[0].db_instance_username}:${random_password.dashboard_service_rds[0].result}@${module.dashboard_service_rds[0].db_instance_address}:${module.dashboard_service_rds[0].db_instance_port}/dashboard_service"
  }
}
