resource "random_password" "rds" {
  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  length  = 32
  special = false
}
