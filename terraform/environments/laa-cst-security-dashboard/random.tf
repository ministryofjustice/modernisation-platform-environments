resource "random_password" "cst_db" {
  length  = 32
  special = false
}

resource "random_password" "cst_db_dev" { # tflint-ignore: terraform_required_providers
  length  = 32
  special = false
}