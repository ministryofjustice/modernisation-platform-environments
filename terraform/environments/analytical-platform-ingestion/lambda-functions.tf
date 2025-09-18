module "definition_upload_lambda" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/lambda/aws"
  version = "8.0.1"

  publish        = true
  create_package = false

  function_name = "definition-upload"
  description   = "Uploads ClamAV definitions to S3 bucket"
  package_type  = "Image"
  memory_size   = 2048
  timeout       = 900
  image_uri     = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/analytical-platform-ingestion-scan:${local.environment_configuration.scan_image_version}"

  vpc_subnet_ids         = module.isolated_vpc.private_subnets
  vpc_security_group_ids = [module.definition_upload_lambda_security_group.security_group_id]
  attach_network_policy  = true

  environment_variables = {
    MODE                         = "definition-upload",
    CLAMAV_DEFINITON_BUCKET_NAME = module.definitions_bucket.s3_bucket_id
  }

  attach_policy_statements = true
  policy_statements = {
    kms_access = {
      sid    = "AllowKMS"
      effect = "Allow"
      actions = [
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:Decrypt"
      ]
      resources = [module.s3_definitions_kms.key_arn]
    },
    s3_access = {
      sid    = "AllowS3"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = ["arn:aws:s3:::${module.definitions_bucket.s3_bucket_id}/*"]
    }
  }

  allowed_triggers = {
    "eventbridge" = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.definition_update.arn
    }
  }
}

module "scan_lambda" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/lambda/aws"
  version = "8.0.1"

  publish        = true
  create_package = false

  function_name          = "scan"
  description            = "Uses ClamAV to scan files"
  package_type           = "Image"
  memory_size            = 2048
  ephemeral_storage_size = 10240
  timeout                = 900
  image_uri              = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/analytical-platform-ingestion-scan:${local.environment_configuration.scan_image_version}"

  vpc_subnet_ids         = module.isolated_vpc.private_subnets
  vpc_security_group_ids = [module.scan_lambda_security_group.security_group_id]
  attach_network_policy  = true

  environment_variables = {
    MODE                         = "scan",
    CLAMAV_DEFINITON_BUCKET_NAME = module.definitions_bucket.s3_bucket_id
    LANDING_BUCKET_NAME          = module.landing_bucket.s3_bucket_id
    QUARANTINE_BUCKET_NAME       = module.quarantine_bucket.s3_bucket_id
    PROCESSED_BUCKET_NAME        = module.processed_bucket.s3_bucket_id
  }

  attach_policy_statements = true
  policy_statements = {
    kms_access = {
      sid    = "AllowKMS"
      effect = "Allow"
      actions = [
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:Decrypt"
      ]
      resources = [
        module.s3_definitions_kms.key_arn,
        module.s3_landing_kms.key_arn,
        module.s3_quarantine_kms.key_arn,
        module.s3_processed_kms.key_arn,
      ]
    },
    s3_access = {
      sid    = "AllowS3"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:CopyObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:PutObjectTagging",
        "s3:GetObjectTagging"
      ]
      resources = [
        "arn:aws:s3:::${module.definitions_bucket.s3_bucket_id}/*",
        "arn:aws:s3:::${module.landing_bucket.s3_bucket_id}/*",
        "arn:aws:s3:::${module.quarantine_bucket.s3_bucket_id}/*",
        "arn:aws:s3:::${module.processed_bucket.s3_bucket_id}/*"
      ]
    }
  }

  allowed_triggers = {
    "s3" = {
      principal  = "s3.amazonaws.com"
      source_arn = module.landing_bucket.s3_bucket_arn
    }
  }
}

module "transfer_lambda" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/lambda/aws"
  version = "8.0.1"

  publish        = true
  create_package = false

  function_name          = "transfer"
  description            = "Transfers files from processed S3 to target S3"
  package_type           = "Image"
  memory_size            = 2048
  ephemeral_storage_size = 10240
  timeout                = 900
  image_uri              = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/analytical-platform-ingestion-transfer:${local.environment_configuration.transfer_image_version}"

  vpc_subnet_ids         = module.isolated_vpc.private_subnets
  vpc_security_group_ids = [module.transfer_lambda_security_group.security_group_id]
  attach_network_policy  = true

  environment_variables = {
    PROCESSED_BUCKET_NAME = module.processed_bucket.s3_bucket_id
    SNS_TOPIC_ARN         = module.transferred_topic.topic_arn
  }

  attach_policy_statements = true
  policy_statements = {
    kms_access = {
      sid    = "AllowKMS"
      effect = "Allow"
      actions = [
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:Decrypt"
      ]
      resources = concat([
        module.s3_processed_kms.key_arn,
        module.supplier_data_kms.key_arn,
        module.transferred_sns_kms.key_arn,
        module.quarantined_sns_kms.key_arn,
      ], coalesce(local.environment_configuration.target_kms_keys, []))
    },
    secretsmanager_access = {
      sid       = "AllowSecretsManager"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:ingestion/*"]
    },
    s3_source_object = {
      sid    = "AllowSourceObject"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:GetObjectTagging"
      ],
      resources = ["arn:aws:s3:::${module.processed_bucket.s3_bucket_id}/*"]
    },
    s3_source_bucket = {
      sid    = "AllowSourceBucket"
      effect = "Allow"
      actions = [
        "s3:ListBucket"
      ],
      resources = ["arn:aws:s3:::${module.processed_bucket.s3_bucket_id}"]
    },
    s3_destination_object = {
      sid    = "AllowDestinationObject"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:PutObjectTagging",
        "s3:GetObjectAcl",
        "s3:PutObjectAcl"
      ]
      resources = formatlist("arn:aws:s3:::%s/*", local.environment_configuration.target_buckets)
    },
    s3_destination_bucket = {
      sid    = "AllowDestinationBucket"
      effect = "Allow"
      actions = [
        "s3:ListBucket"
      ]
      resources = formatlist("arn:aws:s3:::%s", local.environment_configuration.target_buckets)
    },
    sns = {
      sid    = "AllowSNS"
      effect = "Allow"
      actions = [
        "sns:Publish"
      ]
      resources = [module.transferred_topic.topic_arn]
    }
  }

  allowed_triggers = {
    "s3" = {
      principal  = "s3.amazonaws.com"
      source_arn = module.processed_bucket.s3_bucket_arn
    }
  }
}

module "notify_quarantined_lambda" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/lambda/aws"
  version = "8.0.1"

  publish        = true
  create_package = false

  function_name          = "notify-quarantined"
  description            = "Quarantined notifications"
  package_type           = "Image"
  memory_size            = 2048
  ephemeral_storage_size = 10240
  timeout                = 900
  image_uri              = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/analytical-platform-ingestion-notify:${local.environment_configuration.notify_image_version}"

  vpc_subnet_ids         = module.isolated_vpc.private_subnets
  vpc_security_group_ids = [module.transfer_lambda_security_group.security_group_id]
  attach_network_policy  = true

  environment_variables = {
    MODE = "quarantined"
    # GOVUK_NOTIFY_API_KEY_SECRET   = data.aws_secretsmanager_secret_version.govuk_notify_api_key.id
    # GOVUK_NOTIFY_TEMPLATES_SECRET = data.aws_secretsmanager_secret_version.govuk_notify_templates.id
    # SLACK_TOKEN                   = data.aws_secretsmanager_secret_version.slack_token.id
    GOVUK_NOTIFY_API_KEY_SECRET   = "ingestion/govuk-notify/api-key"   #TODO: un-hardcode
    GOVUK_NOTIFY_TEMPLATES_SECRET = "ingestion/govuk-notify/templates" #TODO: un-hardcode
    SLACK_TOKEN_SECRET            = "ingestion/slack-token"            #TODO: un-hardcode
  }

  # TODO: Check if KMS key is actually needed below
  attach_policy_statements = true
  policy_statements = {
    kms_access = {
      sid    = "AllowKMS"
      effect = "Allow"
      actions = [
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:Decrypt"
      ]
      resources = [
        module.quarantined_sns_kms.key_arn,
        module.govuk_notify_kms.key_arn,
        module.slack_token_kms.key_arn,
        module.supplier_data_kms.key_arn
      ]
    },
    secretsmanager_access = {
      sid       = "AllowSecretsManager"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:ingestion/*"]
    }
  }
  allowed_triggers = {
    "sns" = {
      principal  = "sns.amazonaws.com"
      source_arn = "arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${module.quarantined_topic.topic_name}"
    }
  }
}

module "notify_transferred_lambda" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/lambda/aws"
  version = "8.0.1"

  publish        = true
  create_package = false

  function_name          = "notify-transferred"
  description            = "Transferred notifications"
  package_type           = "Image"
  memory_size            = 2048
  ephemeral_storage_size = 10240
  timeout                = 900
  image_uri              = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/analytical-platform-ingestion-notify:${local.environment_configuration.notify_image_version}"

  vpc_subnet_ids         = module.isolated_vpc.private_subnets
  vpc_security_group_ids = [module.transfer_lambda_security_group.security_group_id]
  attach_network_policy  = true

  environment_variables = {
    MODE                          = "transferred"
    GOVUK_NOTIFY_API_KEY_SECRET   = "ingestion/govuk-notify/api-key"   #TODO: un-hardcode
    GOVUK_NOTIFY_TEMPLATES_SECRET = "ingestion/govuk-notify/templates" #TODO: un-hardcode
    SLACK_TOKEN_SECRET            = "ingestion/slack-token"            #TODO: un-hardcode
  }

  # TODO: Check if KMS key is actually needed below
  attach_policy_statements = true
  policy_statements = {
    kms_access = {
      sid    = "AllowKMS"
      effect = "Allow"
      actions = [
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:Decrypt"
      ]
      resources = [
        module.quarantined_sns_kms.key_arn,
        module.govuk_notify_kms.key_arn,
        module.slack_token_kms.key_arn,
        module.supplier_data_kms.key_arn
      ]
    },
    secretsmanager_access = {
      sid       = "AllowSecretsManager"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:ingestion/*"]
    }
  }
  allowed_triggers = {
    "sns" = {
      principal  = "sns.amazonaws.com"
      source_arn = "arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${module.transferred_topic.topic_name}"
    }
  }
}
