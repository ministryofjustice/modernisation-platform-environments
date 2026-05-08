resource "random_password" "litellm_secret_key" {
  length  = 32
  special = false
}

resource "random_password" "rds" {
  length  = 32
  special = false
}

resource "random_password" "elasticache" {
  length  = 32
  special = false
}
