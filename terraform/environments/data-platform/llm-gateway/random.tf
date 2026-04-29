resource "random_password" "litellm_secret_key" {
  length  = 32
  special = false
}
