resource "kubernetes_secret" "rds" {

  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  metadata {
    name      = "rds"
    namespace = kubernetes_namespace.main[0].metadata[0].name
  }

  type = "Opaque"
  data = {
    username                   = module.rds[0].db_instance_username
    password                   = random_password.rds[0].result
    address                    = module.rds[0].db_instance_address
    port                       = module.rds[0].db_instance_port
    database                   = local.db_dbname
    postgres_connection_string = "postgresql://${module.rds[0].db_instance_username}:${random_password.rds[0].result}@${module.rds[0].db_instance_address}:${module.rds[0].db_instance_port}/${local.db_dbname}"
  }
}
