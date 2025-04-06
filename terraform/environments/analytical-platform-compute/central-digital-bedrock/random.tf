# Random string for resource naming/uniqueness
resource "random_string" "vector_db_suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

# Random username for database
resource "random_string" "vector_db_username" {
  length  = 8
  special = false
  upper   = false
  numeric = false
}

# Random password for vector database
resource "random_password" "vector_db" {
  length  = 32
  special = false
}

