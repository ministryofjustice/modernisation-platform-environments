resource "random_password" "openai_proxy" {
  count = local.openai_enabled ? 1 : 0

  length  = 32
  special = false
}

resource "random_password" "litellm_secret_key" {
  length  = 32
  special = false
}

resource "random_password" "litellm_salt_key" {
  length  = 32
  special = false
}

resource "random_password" "aurora" {
  length  = 32
  special = false
}

resource "random_password" "elasticache" {
  length  = 32
  special = false
}
