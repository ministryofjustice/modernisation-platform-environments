resource "random_password" "cst_db" {
  length  = 32
  special = false
}

resource "random_password" "cst_db_dev" {
  length  = 32
  special = false
}