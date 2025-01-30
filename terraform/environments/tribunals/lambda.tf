resource "random_password" "app_new_password" {
  length  = 16
  special = false
}
