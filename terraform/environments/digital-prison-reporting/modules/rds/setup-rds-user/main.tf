locals {
  setup_user = var.setup_additional_users
  roles      = [postgresql_role.this[0].name]
}

provider "postgresql" {
  count           = local.setup_user ? 1 : 0
  host            = var.host
  port            = var.port
  database        = var.database
  username        = var.db_username
  password        = var.db_master_password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = var.superuser
}

resource "postgresql_role" "this" {
  count = local.setup_user ? 1 : 0
  name  = var.rds_role_name
}

resource "postgresql_grant" "readonly" {
  count       = local.setup_user && !var.read_write_role ? 1 : 0
  database    = var.database
  role        = postgresql_role.this[0].name
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "read_write" {
  count       = local.setup_user && var.read_write_role ? 1 : 0
  database    = var.database
  role        = postgresql_role.this[0].name
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT", "UPDATE", "INSERT"]
}

resource "postgresql_role" "main" {
  count    = local.setup_user ? 1 : 0
  name     = "${var.db_username}-role"
  password = var.db_password
  login    = true
  roles    = local.roles
}
