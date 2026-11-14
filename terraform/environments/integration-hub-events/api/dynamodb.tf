# DynamoDB has no auto-increment, so id comes from a counter item stored under id 0 (see lambda/events-ui).
module "events_db" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.2"

  name         = "events_db"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attributes = [{
    name = "id"
    type = "N"
  }]

  server_side_encryption_enabled = true
  point_in_time_recovery_enabled = true
  deletion_protection_enabled    = true
  table_class                    = "STANDARD"

  tags = local.tags
}
