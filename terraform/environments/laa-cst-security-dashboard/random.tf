resource "random_password" "password" {
  count = terraform.workspace == "laa-cst-security-dashboard" ? 1 : 0

  length  = 32
  special = false
}
