module "dynamodb_idempotency" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.1"

  name         = "${local.pattern_name}-idempotency"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attributes = [{
    name = "id"
    type = "S"
  }]

  server_side_encryption_enabled = true
  point_in_time_recovery_enabled = true
  table_class                    = "STANDARD"
  ttl_attribute_name             = "expiration"
  ttl_enabled                    = true

  tags = local.tags
}