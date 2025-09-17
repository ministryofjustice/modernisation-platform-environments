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
