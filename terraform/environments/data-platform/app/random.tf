resource "random_password" "rds" {
  length  = 32
  special = false
}
