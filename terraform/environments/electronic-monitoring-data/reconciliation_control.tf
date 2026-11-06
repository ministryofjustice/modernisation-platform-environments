# ------------------------------------------------------------------------------
# Downstream reconciliation recovery control
# Keep one active review or recovery episode per environment and consumer.
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "downstream_reconciliation_control" {
  name         = "downstream-reconciliation-control"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "control_key"

  attribute {
    name = "control_key"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  deletion_protection_enabled = local.is-production

  tags = local.tags
}
