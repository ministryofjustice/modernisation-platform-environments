locals {
  eks_cluster_name     = "${local.application_name}-${local.environment}"
  db_subnet_group_name = "${local.application_name}-${local.environment}"
  db_dbname            = "${local.component_name}db"
  db_dbuser            = "${local.component_name}user"
  our_vpc_name         = "${local.application_name}-${local.environment}"
}
