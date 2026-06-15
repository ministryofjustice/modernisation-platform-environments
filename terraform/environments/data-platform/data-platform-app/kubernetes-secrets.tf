resource "kubernetes_secret_v1" "data_platform_app_rds" {
  count = terraform.workspace == "data-platform-test" ? 0 : 1

  metadata {
    name      = "data-platform-app-rds"
    namespace = kubernetes_namespace_v1.data_platform_app[0].metadata[0].name
  }

  type = "Opaque"
  data = {
    username                   = module.data_platform_app_rds[0].db_instance_username
    password                   = random_password.data_platform_app_rds[0].result
    address                    = module.data_platform_app_rds[0].db_instance_address
    port                       = module.data_platform_app_rds[0].db_instance_port
    postgres_connection_string = "postgresql://${module.data_platform_app_rds[0].db_instance_username}:${random_password.data_platform_app_rds[0].result}@${module.data_platform_app_rds[0].db_instance_address}:${module.data_platform_app_rds[0].db_instance_port}/data_platform_app"
  }
}
