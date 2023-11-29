resource "random_password" "datahub_rds" {
  length  = 32
  special = false
}
resource "random_password" "opensearch" {
  length           = 64
  special          = true
  override_special = "_%@"
  min_numeric      = 1
  min_lower        = 1
  min_upper        = 1
  min_special      = 1
}
