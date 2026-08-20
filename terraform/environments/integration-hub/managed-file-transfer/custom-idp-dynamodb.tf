module "dynamodb_custom_idp_users" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name         = "${local.application_name}-${local.component_name}-custom-idp-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user"
  range_key    = "identity_provider_key"

  attributes = [
    {
      name = "user"
      type = "S"
    },
    {
      name = "identity_provider_key"
      type = "S"
    }
  ]

  point_in_time_recovery_enabled = true
  table_class                    = "STANDARD"
  timeouts = {
    create = "60m"
    delete = "60m"
    update = "60m"
  }

  tags = local.tags
}

module "dynamodb_custom_idp_identity_providers" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name         = "${local.application_name}-${local.component_name}-custom-idp-identity-providers"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "provider"

  attributes = [
    {
      name = "provider"
      type = "S"
    }
  ]

  point_in_time_recovery_enabled = true
  table_class                    = "STANDARD"
  timeouts = {
    create = "60m"
    delete = "60m"
    update = "60m"
  }

  tags = local.tags
}

resource "aws_dynamodb_table_item" "custom_idp_identity_provider_secrets" {
  table_name = module.dynamodb_custom_idp_identity_providers.dynamodb_table_id
  hash_key   = "provider"

  item = jsonencode({
    provider = {
      S = "secrets"
    }
    module = {
      S = "secrets_manager"
    }
    public_key_support = {
      BOOL = true
    }
    config = {
      M = {
        secret_prefix = {
          S = local.custom_idp_configuration.secret_prefix
        }
      }
    }
  })
}

resource "aws_dynamodb_table_item" "custom_idp_user" {
  for_each = local.custom_idp_users

  table_name = module.dynamodb_custom_idp_users.dynamodb_table_id
  hash_key   = "user"
  range_key  = "identity_provider_key"

  item = jsonencode({
    user = {
      S = each.key
    }
    identity_provider_key = {
      S = try(each.value.identity_provider_key, "secrets")
    }
    ipv4_allow_list = {
      SS = try(each.value.ipv4_allow_list, local.custom_idp_configuration.ingress_cidr_blocks)
    }
    config = {
      M = {
        Role = {
          S = module.transfer_user_role.arn
        }
        Policy = {
          S = data.aws_iam_policy_document.transfer_user_session.json
        }
        HomeDirectoryType = {
          S = "LOGICAL"
        }
        HomeDirectoryDetails = {
          L = [
            {
              M = {
                Entry = {
                  S = "/"
                }
                Target = {
                  S = "/${module.s3_bucket["unscanned"].s3_bucket_id}/${trimprefix(try(each.value.home_directory_target, each.key), "/")}"
                }
              }
            }
          ]
        }
      }
    }
  })
}
