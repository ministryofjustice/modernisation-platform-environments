locals {
  custom_idp_name                          = "${local.application_name}-${local.component_name}-custom-idp"
  custom_idp_users_table_name              = var.custom_idp_existing_users_table_name != "" ? var.custom_idp_existing_users_table_name : try(module.custom_idp_users_table[0].dynamodb_table_id, null)
  custom_idp_users_table_arn               = var.custom_idp_existing_users_table_name != "" ? data.aws_dynamodb_table.custom_idp_users[0].arn : try(module.custom_idp_users_table[0].dynamodb_table_arn, null)
  custom_idp_identity_providers_table_name = var.custom_idp_existing_identity_providers_table_name != "" ? var.custom_idp_existing_identity_providers_table_name : try(module.custom_idp_identity_providers_table[0].dynamodb_table_id, null)
  custom_idp_identity_providers_table_arn  = var.custom_idp_existing_identity_providers_table_name != "" ? data.aws_dynamodb_table.custom_idp_identity_providers[0].arn : try(module.custom_idp_identity_providers_table[0].dynamodb_table_arn, null)
  custom_idp_vpc_security_group_ids        = var.custom_idp_attach_vpc ? [aws_security_group.custom_idp[0].id] : null
  custom_idp_vpc_subnet_ids                = var.custom_idp_attach_vpc ? module.isolated_vpc.private_subnets : null
  custom_idp_optional_policy_statements = var.custom_idp_allow_secrets_manager ? {
    secrets_manager_read = {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
      ]
      resources = [
        "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:*",
      ]
    }
  } : {}
}

data "aws_dynamodb_table" "custom_idp_users" {
  count = var.enable_custom_idp && var.custom_idp_existing_users_table_name != "" ? 1 : 0

  name = var.custom_idp_existing_users_table_name
}

data "aws_dynamodb_table" "custom_idp_identity_providers" {
  count = var.enable_custom_idp && var.custom_idp_existing_identity_providers_table_name != "" ? 1 : 0

  name = var.custom_idp_existing_identity_providers_table_name
}

resource "aws_security_group" "custom_idp" {
  count = var.enable_custom_idp && var.custom_idp_attach_vpc ? 1 : 0

  description = "Outbound access for the future Transfer custom identity provider Lambda"
  name        = "${local.custom_idp_name}-lambda"
  vpc_id      = module.isolated_vpc.vpc_id

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

module "custom_idp_users_table" {
  count = var.enable_custom_idp && var.custom_idp_existing_users_table_name == "" ? 1 : 0

  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name         = "${local.custom_idp_name}-users"
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

  table_class = "STANDARD"

  tags = local.tags
}

module "custom_idp_identity_providers_table" {
  count = var.enable_custom_idp && var.custom_idp_existing_identity_providers_table_name == "" ? 1 : 0

  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name         = "${local.custom_idp_name}-identity-providers"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "provider"

  attributes = [
    {
      name = "provider"
      type = "S"
    }
  ]

  table_class = "STANDARD"

  tags = local.tags
}

module "lambda_custom_idp" {
  count = var.enable_custom_idp ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                = local.custom_idp_name
  description                  = "Future AWS Transfer Family custom identity provider foundations"
  handler                      = "app.lambda_handler"
  runtime                      = "python3.11"
  source_path                  = [{ path = "${path.module}/lambda/custom-idp", pip_requirements = true }]
  trigger_on_package_timestamp = false
  timeout                      = 45
  memory_size                  = 1024

  attach_network_policy = var.custom_idp_attach_vpc
  attach_tracing_policy = var.custom_idp_enable_tracing
  tracing_mode          = var.custom_idp_enable_tracing ? "Active" : null

  vpc_subnet_ids         = local.custom_idp_vpc_subnet_ids
  vpc_security_group_ids = local.custom_idp_vpc_security_group_ids

  environment_variables = {
    AWS_XRAY_TRACING_NAME    = local.custom_idp_name
    IDENTITY_PROVIDERS_TABLE = local.custom_idp_identity_providers_table_name
    LOGLEVEL                 = upper(var.custom_idp_log_level)
    POWERTOOLS_SERVICE_NAME  = local.custom_idp_name
    USER_NAME_DELIMITER      = var.custom_idp_username_delimiter
    USERS_TABLE              = local.custom_idp_users_table_name
  }

  attach_policy_statements = true
  policy_statements = merge(
    {
      transfer_describe_server = {
        effect = "Allow"
        actions = [
          "transfer:DescribeServer",
        ]
        resources = [
          "arn:aws:transfer:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:server/*",
        ]
      }
      dynamodb_read = {
        effect = "Allow"
        actions = [
          "dynamodb:GetItem",
          "dynamodb:Query",
        ]
        resources = [
          local.custom_idp_identity_providers_table_arn,
          local.custom_idp_users_table_arn,
        ]
      }
    },
    local.custom_idp_optional_policy_statements,
  )

  cloudwatch_logs_retention_in_days = 30

  tags = local.tags
}