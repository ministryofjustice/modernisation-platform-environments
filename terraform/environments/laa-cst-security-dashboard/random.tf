resource "random_password" "cst_db" {
  count = terraform.workspace == "laa-cst-security-dashboard" ? 1 : 0

  length  = 32
  special = false
}

resource "random_password" "cst_db_dev" {
  count = terraform.workspace == "laa-cst-security-dashboard" ? 1 : 0

  length  = 32
  special = false
}