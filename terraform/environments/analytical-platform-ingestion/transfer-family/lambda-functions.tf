module "transfer_service_lambda" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/lambda/aws"
  version = "7.20.1"

  publish        = true
  create_package = false

  function_name          = "transfer-service"
  description            = "Transfer Service Lambda"
  package_type           = "Image"
  memory_size            = 2048
  ephemeral_storage_size = 10240
  timeout                = 900
  image_uri              = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/analytical-platform-ingestion-transfer:${local.environment_configuration.transfer_service_image_version}"

  vpc_subnet_ids         = data.aws_subnets.isolated_private.ids
  vpc_security_group_ids = [module.transfer_service_lambda_security_group.security_group_id]
  attach_network_policy  = true

  environment_variables = {
    LANDING_BUCKET_NAME    = module.transfer_landing_bucket.s3_bucket_id
    QUARANTINE_BUCKET_NAME = module.transfer_quarantine_bucket.s3_bucket_id
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
        module.s3_transfer_landing_kms.key_arn,
        local.environment_configuration.mojap_land_kms_key,
        module.supplier_data_kms.key_arn,
        module.transfer_service_sns_kms.key_arn
      ]
    },
    secretsmanager_access = {
      sid       = "AllowSecretsManager"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:ingestion/*"]
    },
    s3_source_object = {
      sid    = "AllowSourceObject"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:GetObjectTagging"
      ],
      resources = ["arn:aws:s3:::${module.transfer_landing_bucket.s3_bucket_id}/*"]
    },
    s3_source_bucket = {
      sid    = "AllowSourceBucket"
      effect = "Allow"
      actions = [
        "s3:ListBucket"
      ],
      resources = ["arn:aws:s3:::${module.transfer_landing_bucket.s3_bucket_id}"]
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
      resources = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:transfer-service*"]
    }
  }
}
