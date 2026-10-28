data "aws_kms_key" "secrets" {
  key_id = local.secrets_kms_key_alias
}

data "aws_kms_key" "logs" {
  key_id = local.logs_kms_key_alias
}

module "lambda_file_mover" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.9.0"

  architectures                     = ["arm64"]
  attach_tracing_policy             = true
  attach_network_policy             = true
  build_in_docker                   = true
  docker_image                      = "public.ecr.aws/sam/build-python3.12:latest-arm64"
  docker_additional_options         = ["--platform", "linux/arm64"]
  cloudwatch_logs_kms_key_id        = data.aws_kms_key.logs.arn
  cloudwatch_logs_retention_in_days = 90
  description                       = "Deliver exact clean object versions to configured SFTP destinations"
  function_name                     = local.pattern_name
  handler                           = "handler.lambda_handler"
  ignore_source_code_hash           = true
  memory_size                       = 512
  role_name                         = local.lambda_role_name
  runtime                           = "python3.12"
  source_path                       = local.lambda_source_path
  hash_extra                        = "file-mover"
  timeout                           = 900
  tracing_mode                      = "Active"
  vpc_subnet_ids                    = local.writer_subnet_ids
  vpc_security_group_ids            = [module.security_group_writer.id]

  environment_variables = merge(local.lambda_environment, {
    POWERTOOLS_SERVICE_NAME = local.pattern_name
  })

  event_source_mapping = {
    processing = {
      event_source_arn        = module.sqs_processing.queue_arn
      enabled                 = local.delivery_enabled
      batch_size              = 1
      function_response_types = ["ReportBatchItemFailures"]
      scaling_config = {
        maximum_concurrency = 5
      }
    }
  }

  attach_policy_statements = true
  policy_statements = merge({
    consume_queue = {
      effect = "Allow"
      actions = [
        "sqs:ChangeMessageVisibility",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ReceiveMessage",
      ]
      resources = [module.sqs_processing.queue_arn]
    }
    decrypt_queue = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [module.kms_transport.key_arn]
    }
    publish_completion = {
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [data.aws_cloudwatch_event_bus.file_transfer.arn]
    }
    use_idempotency_table = {
      effect    = "Allow"
      actions   = ["dynamodb:DeleteItem", "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem"]
      resources = [module.dynamodb_idempotency.dynamodb_table_arn]
    }
    }, length(local.push_to_sftp_entries) == 0 ? {} : {
    read_dispatch_configuration = {
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [for arn_prefix in values(local.dispatch_secret_arn_prefixes) : "${arn_prefix}??????"]
    }
    decrypt_dispatch_configuration = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [data.aws_kms_key.secrets.arn]
    }
    assume_delivery_roles = {
      effect    = "Allow"
      actions   = ["sts:AssumeRole"]
      resources = [for role in module.iam_role_delivery : role.arn]
    }
  })

  tags = local.tags

  depends_on = [terraform_data.delivery_configuration]
}

resource "terraform_data" "delivery_configuration" {
  lifecycle {
    precondition {
      condition     = length(local.writer_subnet_ids) > 0 && data.aws_region.current.region == "eu-west-2"
      error_message = "SFTP requires shared private subnets in eu-west-2."
    }

    precondition {
      condition     = alltrue([for name in values(local.delivery_resource_names) : length(name) <= 64])
      error_message = "Push-to-SFTP delivery role names must be at most 64 characters."
    }

    precondition {
      condition = alltrue([
        for entry in values(local.push_to_sftp_entries) :
        !startswith(entry.action.push_to_sftp.destination_prefix, "/") &&
        (entry.action.push_to_sftp.destination_prefix == "" || endswith(entry.action.push_to_sftp.destination_prefix, "/")) &&
        alltrue([for segment in split("/", trimsuffix(entry.action.push_to_sftp.destination_prefix, "/")) :
          entry.action.push_to_sftp.destination_prefix == "" || (segment != "" && segment != "." && segment != "..")
        ]) &&
        length(regexall("[\\\\\\x00-\\x1f\\x7f]", entry.action.push_to_sftp.destination_prefix)) == 0
      ])
      error_message = "SFTP destination prefixes must be empty or safe relative directories ending in '/'."
    }

    precondition {
      condition = alltrue([
        for entry in values(local.push_to_sftp_entries) :
        length(entry.action.push_to_sftp.destination_cidr_blocks) > 0 &&
        alltrue([for cidr in entry.action.push_to_sftp.destination_cidr_blocks :
          can(cidrnetmask(cidr)) && try(tonumber(split("/", cidr)[1]) > 0, false)
        ]) &&
        try(entry.action.push_to_sftp.port, 22) >= 1 &&
        try(entry.action.push_to_sftp.port, 22) <= 65535 &&
        floor(try(entry.action.push_to_sftp.port, 22)) == try(entry.action.push_to_sftp.port, 22) &&
        length(entry.action.push_to_sftp.host_public_keys) > 0
      ])
      error_message = "SFTP requires explicit IPv4 recipient CIDRs (not /0), a valid integer TCP port and trusted host public keys."
    }
  }
}

module "lambda_dlq_reporter" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.9.0"

  architectures                     = ["arm64"]
  attach_tracing_policy             = true
  build_in_docker                   = true
  docker_image                      = "public.ecr.aws/sam/build-python3.12:latest-arm64"
  docker_additional_options         = ["--platform", "linux/arm64"]
  cloudwatch_logs_kms_key_id        = data.aws_kms_key.logs.arn
  cloudwatch_logs_retention_in_days = 90
  description                       = "Report terminal push-to-sftp delivery outcomes from the three DLQs"
  function_name                     = "${local.pattern_name}-dlq"
  handler                           = "reporter_handler.lambda_handler"
  ignore_source_code_hash           = true
  memory_size                       = 256
  role_name                         = "${local.pattern_name}-dlq"
  runtime                           = "python3.12"
  source_path                       = local.lambda_source_path
  hash_extra                        = "dlq-reporter"
  timeout                           = 60
  tracing_mode                      = "Active"

  environment_variables = merge(local.lambda_environment, {
    DLQ_ARNS                = jsonencode(local.dlq_arns)
    POWERTOOLS_SERVICE_NAME = "${local.pattern_name}-dlq-reporter"
  })

  event_source_mapping = {
    for name, arn in local.dlq_arns : name => {
      event_source_arn        = arn
      enabled                 = true
      batch_size              = 10
      function_response_types = ["ReportBatchItemFailures"]
      scaling_config = {
        maximum_concurrency = 2
      }
    }
  }

  attach_policy_statements = true
  policy_statements = {
    consume_dlqs = {
      effect    = "Allow"
      actions   = ["sqs:ChangeMessageVisibility", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"]
      resources = values(local.dlq_arns)
    }
    decrypt_dlqs = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [module.kms_transport.key_arn]
    }
    terminal_outcomes = {
      effect    = "Allow"
      actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem"]
      resources = [module.dynamodb_idempotency.dynamodb_table_arn]
    }
    publish_completion = {
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [data.aws_cloudwatch_event_bus.file_transfer.arn]
    }
  }

  tags = local.tags
}