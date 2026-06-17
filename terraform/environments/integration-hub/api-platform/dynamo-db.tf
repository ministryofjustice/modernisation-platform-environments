module "dynamodb_transfer_clients" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name         = "${local.application_name}-${local.component_name}-transfer-clients"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "client_id"

  attributes = [
    {
      name = "client_id"
      type = "S"
    }
  ]

  table_class = "STANDARD"
  timeouts = {
    create = "60m"
    delete = "60m"
    update = "60m"
  }

  tags = local.tags
}

resource "aws_dynamodb_table_item" "transfer_client" {
  for_each = local.transfer_clients

  table_name = module.dynamodb_transfer_clients.dynamodb_table_id
  hash_key   = "client_id"

  item = jsonencode({
    client_id = {
      S = each.key
    }
    enabled = {
      BOOL = try(each.value.enabled, true)
    }
    key_prefix = {
      S = try(each.value.key_prefix, each.key)
    }
    max_upload_size_bytes = {
      N = tostring(try(each.value.max_upload_size_bytes, 107374182400))
    }
    allowed_content_types = {
      L = [
        for value in try(each.value.allowed_content_types, []) : {
          S = value
        }
      ]
    }
  })
}
