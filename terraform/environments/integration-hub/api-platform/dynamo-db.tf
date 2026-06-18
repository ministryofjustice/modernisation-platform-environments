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

module "dynamodb_auth_roles" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name         = "${local.application_name}-${local.component_name}-auth-roles"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "role_name"

  attributes = [
    {
      name = "role_name"
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

module "dynamodb_auth_principals" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name         = "${local.application_name}-${local.component_name}-auth-principals"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "auth_lookup_key"

  attributes = [
    {
      name = "auth_lookup_key"
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

resource "aws_dynamodb_table_item" "auth_role" {
  for_each = local.auth_roles

  table_name = module.dynamodb_auth_roles.dynamodb_table_id
  hash_key   = "role_name"

  item = jsonencode({
    role_name = {
      S = each.key
    }
    allowed_client_ids = {
      L = [
        for client_id in try(each.value.allowed_client_ids, []) : {
          S = client_id
        }
      ]
    }
  })
}

resource "aws_dynamodb_table_item" "auth_user_principal" {
  for_each = local.auth_users

  table_name = module.dynamodb_auth_principals.dynamodb_table_id
  hash_key   = "auth_lookup_key"

  item = jsonencode({
    auth_lookup_key = {
      S = "basic#${each.key}"
    }
    principal_id = {
      S = each.key
    }
    auth_type = {
      S = "basic"
    }
    enabled = {
      BOOL = try(each.value.enabled, true)
    }
    role_name = {
      S = each.value.role_name
    }
    secret_name = {
      S = module.api_user_credentials_secret[each.key].secret_name
    }
  })
}

resource "aws_dynamodb_table_item" "auth_system_principal" {
  for_each = local.auth_system_principals

  table_name = module.dynamodb_auth_principals.dynamodb_table_id
  hash_key   = "auth_lookup_key"

  item = jsonencode({
    auth_lookup_key = {
      S = "bearer#${each.key}"
    }
    principal_id = {
      S = each.key
    }
    auth_type = {
      S = "bearer"
    }
    enabled = {
      BOOL = try(each.value.enabled, true)
    }
    role_name = {
      S = each.value.role_name
    }
    secret_name = {
      S = module.api_system_bearer_token_secret[each.key].secret_name
    }
  })
}
