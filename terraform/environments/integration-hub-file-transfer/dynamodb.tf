module "dynamodb_adapter_idempotency" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name         = "${local.application_name}-${local.environment}-adapter-idempotency"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]

  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = module.kms_dynamodb.key_arn
  table_class                        = "STANDARD"
  ttl_attribute_name                 = "expiration"
  ttl_enabled                        = true
  timeouts = {
    "create" : "60m",
    "delete" : "60m",
    "update" : "60m"
  }
}

module "dynamodb_file_transfer_workflow_idempotency" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name         = "${local.application_name}-${local.environment}-file-transfer-workflow-idempotency"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attributes = [
    {
      name = "id"
      type = "S"
    },
    {
      name = "processing_object_id"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name            = "processing-object-id-index"
      hash_key        = "processing_object_id"
      projection_type = "ALL"
    }
  ]

  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = module.kms_dynamodb.key_arn
  table_class                        = "STANDARD"
  ttl_attribute_name                 = "expiration"
  ttl_enabled                        = true
  timeouts = {
    "create" : "60m",
    "delete" : "60m",
    "update" : "60m"
  }

  tags = local.tags
}