module "dynamodb_auth_roles" {
  count = local.create_service ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-dynamodb-table.git?ref=45c9cb10c2f6209e7362bba92cadd5ab3c9e2003" # v5.5.0

  name         = "${local.application_name}-${local.component_name}-auth-roles"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "role_name"
  attributes = [{
    name = "role_name"
    type = "S"
  }]
  tags = local.tags
}

module "dynamodb_auth_principals" {
  count = local.create_service ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-dynamodb-table.git?ref=45c9cb10c2f6209e7362bba92cadd5ab3c9e2003" # v5.5.0

  name         = "${local.application_name}-${local.component_name}-auth-principals"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "auth_lookup_key"
  attributes = [{
    name = "auth_lookup_key"
    type = "S"
  }]
  tags = local.tags
}

resource "aws_dynamodb_table_item" "auth_role" {
  for_each = local.create_service ? local.auth_roles : {}

  table_name = module.dynamodb_auth_roles[0].dynamodb_table_id
  hash_key   = "role_name"
  item       = jsonencode({ role_name = { S = each.key } })
}

resource "aws_dynamodb_table_item" "auth_user_principal" {
  for_each = local.create_service ? local.auth_users : {}

  table_name = module.dynamodb_auth_principals[0].dynamodb_table_id
  hash_key   = "auth_lookup_key"
  item = jsonencode({
    auth_lookup_key = { S = "basic#${each.key}" }
    principal_id    = { S = each.key }
    auth_type       = { S = "basic" }
    enabled         = { BOOL = try(each.value.enabled, true) }
    role_name       = { S = each.value.role_name }
    secret_name     = { S = module.api_user_credentials_secret[each.key].secret_name }
  })
}

resource "aws_dynamodb_table_item" "auth_system_principal" {
  for_each = local.create_service ? local.auth_system_principals : {}

  table_name = module.dynamodb_auth_principals[0].dynamodb_table_id
  hash_key   = "auth_lookup_key"
  item = jsonencode({
    auth_lookup_key = { S = "bearer#${each.key}" }
    principal_id    = { S = each.key }
    auth_type       = { S = "bearer" }
    enabled         = { BOOL = try(each.value.enabled, true) }
    role_name       = { S = each.value.role_name }
    secret_name     = { S = module.api_system_bearer_token_secret[each.key].secret_name }
  })
}
