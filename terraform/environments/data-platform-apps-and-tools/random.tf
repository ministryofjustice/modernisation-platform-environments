resource "random_password" "datahub_rds" {
  length  = 32
  special = false
}
