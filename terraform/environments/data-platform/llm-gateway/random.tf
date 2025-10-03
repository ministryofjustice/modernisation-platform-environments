resource "random_password" "litellm_secret_key" {
  count = terraform.workspace == "data-platform-development" ? 1 : 0

  length  = 32
  special = false
}
