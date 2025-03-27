resource "aws_dynamodb_table" "github_repos_state_lock" {
  name         = "github_repos_state_lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  ttl {
    attribute_name = "Expires"
    enabled        = true
  }
}