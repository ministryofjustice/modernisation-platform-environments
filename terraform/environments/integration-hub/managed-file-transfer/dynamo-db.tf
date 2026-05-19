module "dynamodb_idempotency" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name         = "integration-hub-s3-idempotency"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]

  table_class        = "STANDARD"
  ttl_attribute_name = "expiration"
  ttl_enabled        = true
  timeouts = {
    "create" : "60m",
    "delete" : "60m",
    "update" : "60m"
  }
}