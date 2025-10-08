locals {
  secret_names = [
    "LAA-ftp-allpay-inbound-ccms",
    "LAA-ftp-rossendales-ccms-inbound",
    "LAA-ftp-eckoh-inbound-ccms",
    "LAA-ftp-1stlocate-ccms-inbound",
    "LAA-ftp-xerox-outbound"
  ]
  base_buckets = ["laa-ccms-inbound", "laa-ccms-outbound", "laa-ccms-ftp-lambda"]

  bucket_names = [
    for name in local.base_buckets : "${name}-${local.environment}-mp"
  ]
  enable_cron_in_environments = [
    "development",
    "test",
    "preproduction"
  ]
}

### secrets for ftp user and password
resource "aws_secretsmanager_secret" "secrets" {
  for_each = toset(local.secret_names)

  name = "${each.value}-${local.environment}"
}


# Reference the secret for ccms-ebs ftp server
data "aws_secretsmanager_secret" "ftp_test_user_secret" {
  name = "ftp-s3-${local.environment}-aws-key"
}

# Get the latest version of the secret value for ccms-ebs ftp server
data "aws_secretsmanager_secret_version" "ftp_test_user_secret_value" {
  secret_id = data.aws_secretsmanager_secret.ftp_test_user_secret.id
}

locals {
  ftp_test_user_secret_value = jsondecode(data.aws_secretsmanager_secret_version.ftp_test_user_secret_value.secret_string)
}

resource "aws_s3_bucket" "buckets" {
  for_each = toset(local.bucket_names)

  bucket = each.value

  tags = merge(
    {
      Name        = each.value
      Environment = local.environment
    },
    {
      "business-unit"          = "LAA",
      "infrastructure-support" = "laa-role-sre@digital.justice.gov.uk",
      "source-code"            = "https://github.com/ministryofjustice/modernisation-platform-environments"
    }
  )

  # server access logging is configured via aws_s3_bucket_logging resource below
}

# Server access logging: send access logs to the environment logging bucket
resource "aws_s3_bucket_logging" "buckets_access_logging" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  target_bucket = local.logging_bucket_name
  target_prefix = "s3-access-logs/${each.key}/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  for_each = aws_s3_bucket.buckets
  bucket   = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle configuration: expire current objects and noncurrent versions after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "buckets_lifecycle" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id

  rule {
    id     = local.is-production ? "expire-90-days" : "expire-30-days"
    status = "Enabled"

    expiration {
      days = local.is-production ? 90 : 30
    }

    noncurrent_version_expiration {
      noncurrent_days = local.is-production ? 90 : 30
    }
  }
}

#--Dynamic blocks for transfer family policy in production only
data "aws_iam_policy_document" "inbound_bucket_policy" {
  statement {
    sid    = "Access_for_ccms-ebs_and_soa"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["laa-ccms-soa-${local.environment}"]}:role/ccms-soa-ec2-instance-role",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/role_stsassume_oracle_base"
      ]
    }
    resources = [
      aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].arn,
      "${aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].arn}/*"
    ]
  }

  #--Cash office. Transfer family. Production only.
  dynamic "statement" {
    for_each = (local.is-preproduction || local.is-production) ? [1] : []
    content {
      sid     = "Access_for_s3_transfer_family_list"
      effect  = "Allow"
      actions = ["s3:ListBucket"]
      principals {
        type        = "AWS"
        identifiers = [module.transfer_family[0].grant_iam_role_arn]
      }
      resources = [
        aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].arn
      ]
    }
  }

  #--Cash office. Transfer family. Production only.
  dynamic "statement" {
    for_each = (local.is-preproduction || local.is-production) ? [1] : []
    content {
      sid    = "Access_for_s3_transfer_family_contents"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetObjectAcl",
        "s3:GetObjectVersionAcl",
        "s3:ListMultipartUploadParts",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:PutObjectVersionAcl",
        "s3:AbortMultipartUpload"
      ]
      principals {
        type        = "AWS"
        identifiers = [module.transfer_family[0].grant_iam_role_arn]
      }
      resources = [
        "${aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].arn}/*"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "inbound_bucket_policy" {
  bucket = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  policy = data.aws_iam_policy_document.inbound_bucket_policy.json
}

#--Cash office. Transfer family CORS. Production only
resource "aws_s3_bucket_cors_configuration" "inbound_bucket_cors_policy" {
  count  = (local.is-preproduction || local.is-production) ? 1 : 0
  bucket = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["https://${local.application_data.accounts[local.environment].cash_office_upload_hostname}.${trim(data.aws_route53_zone.external.name, ".")}"]
    expose_headers = [
      "last-modified",
      "content-length",
      "etag",
      "x-amz-version-id",
      "content-type",
      "x-amz-request-id",
      "x-amz-id-2",
      "date",
      "x-amz-cf-id",
      "x-amz-storage-class",
      "access-control-expose-headers"
    ]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "outbound_bucket_policy" {
  bucket = aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].bucket

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "AccessFromMP",
    "Statement" : [
      {
        "Sid" : "Access_for_ccms-ebs_and_soa",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.environment_management.account_ids["laa-ccms-soa-${local.environment}"]}:role/ccms-soa-ec2-instance-role",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/role_stsassume_oracle_base"
          ]
        },
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        "Resource" : [
          aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].arn,
          "${aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].arn}/*"
        ]
      }
    ]
    }
  )
}

resource "aws_s3_object" "ftp_lambda_layer" {
  bucket = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  key    = "lambda/ftp_lambda_layer.zip"
  source = "lambda/ftp_lambda_layer.zip"
}

resource "aws_s3_object" "ftp_client" {
  bucket = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  key    = "lambda/ftp-client-v3.1.zip"
  source = "lambda/ftp-client-v3.1.zip"
}

# #LAA-ftp-allpay-outbound-ccms
module "allpay_ftp_lambda_outbound" {
  source                   = "./modules/ftp-lambda"
  lambda_name              = lower(format("LAA-ftp-allpay-outbound-ccms-%s", local.environment))
  vpc_id                   = data.aws_vpc.shared.id
  subnet_ids               = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type        = "SFTP_UPLOAD"
  ftp_local_path           = "CCMS_PRD_Allpay/Outbound/"
  ftp_remote_path          = lower(local.environment) == "production" ? "/Inbound/" : "/home/${local.ftp_test_user_secret_value["USER"]}/laa-ccms-outbound-${local.environment}-mp/outbound-lambda-runs/"
  ftp_bucket               = aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].bucket
  env                      = local.environment
  secret_name              = "LAA-ftp-allpay-inbound-ccms-${local.environment}"
  secret_arn               = aws_secretsmanager_secret.secrets["LAA-ftp-allpay-inbound-ccms"].arn
  s3_bucket_ftp            = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key
  s3_object_ftp_client     = aws_s3_object.ftp_client.key
  #ftp_cron                     = "cron(0 10 * * ? *)"
  enabled_cron_in_environments = local.enable_cron_in_environments
}


# #LAA-ftp-allpay-inbound-ccms
module "allpay_ftp_lambda_inbound" {
  source                   = "./modules/ftp-lambda"
  lambda_name              = lower(format("LAA-ftp-allpay-inbound-ccms-%s", local.environment))
  vpc_id                   = data.aws_vpc.shared.id
  subnet_ids               = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type        = "SFTP_DOWNLOAD"
  ftp_local_path           = "CCMS_PRD_Allpay/Inbound/"
  ftp_remote_path          = lower(local.environment) == "production" ? "/Outbound/" : "/home/${local.ftp_test_user_secret_value["USER"]}/laa-ccms-inbound-${local.environment}-mp/inbound-lambda-runs/"
  ftp_bucket               = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  env                      = local.environment
  secret_name              = "LAA-ftp-allpay-inbound-ccms-${local.environment}"
  secret_arn               = aws_secretsmanager_secret.secrets["LAA-ftp-allpay-inbound-ccms"].arn
  s3_bucket_ftp            = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key
  s3_object_ftp_client     = aws_s3_object.ftp_client.key
  #ftp_cron                     = "cron(0 10 * * ? *)"
  enabled_cron_in_environments = local.enable_cron_in_environments
}

#LAA-xerox-outbound-ccms
module "LAA-ftp-xerox-ccms-outbound" {
  source                   = "./modules/ftp-lambda"
  lambda_name              = lower(format("LAA-ftp-xerox-ccms-outbound-%s", local.environment))
  vpc_id                   = data.aws_vpc.shared.id
  subnet_ids               = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type        = "SFTP_UPLOAD"
  ftp_local_path           = "CCMS_PRD_DST/Outbound/"
  ftp_remote_path          = lower(local.environment) == "production" ? "/Production/outbound/CCMS/" : "/home/${local.ftp_test_user_secret_value["USER"]}/laa-ccms-outbound-${local.environment}-mp/outbound-lambda-runs/"
  ftp_file_types           = "zip"
  ftp_bucket               = aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].bucket
  env                      = local.environment
  secret_name              = "LAA-ftp-xerox-outbound-${local.environment}"
  secret_arn               = aws_secretsmanager_secret.secrets["LAA-ftp-xerox-outbound"].arn
  s3_bucket_ftp            = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key
  s3_object_ftp_client     = aws_s3_object.ftp_client.key
  #ftp_cron                     = "cron(0 10 * * ? *)"
  enabled_cron_in_environments = local.enable_cron_in_environments
}

#LAA-xerox-outbound-ccms-peterborough
module "LAA-ftp-xerox-ccms-outbound-peterborough" {
  source                   = "./modules/ftp-lambda"
  lambda_name              = lower(format("LAA-ftp-xerox-ccms-outbound-peterborough-%s", local.environment))
  vpc_id                   = data.aws_vpc.shared.id
  subnet_ids               = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type        = "SFTP_UPLOAD"
  ftp_local_path           = "CCMS_PRD_DST/Outbound/Peterborough/"
  ftp_remote_path          = lower(local.environment) == "production" ? "/Production/outbound/PETER/" : "/home/${local.ftp_test_user_secret_value["USER"]}/laa-ccms-outbound-${local.environment}-mp/outbound-lambda-runs/"
  ftp_bucket               = aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].bucket
  env                      = local.environment
  secret_name              = "LAA-ftp-xerox-outbound-${local.environment}"
  secret_arn               = aws_secretsmanager_secret.secrets["LAA-ftp-xerox-outbound"].arn
  s3_bucket_ftp            = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key
  s3_object_ftp_client     = aws_s3_object.ftp_client.key
  #ftp_cron                     = "cron(0 10 * * ? *)"
  enabled_cron_in_environments = local.enable_cron_in_environments
}

# #LAA-ftp-eckoh-outbound-ccms
module "LAA-ftp-eckoh-outbound-ccms" {
  source                   = "./modules/ftp-lambda"
  lambda_name              = lower(format("LAA-ftp-eckoh-outbound-ccms-%s", local.environment))
  vpc_id                   = data.aws_vpc.shared.id
  subnet_ids               = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type        = "SFTP_UPLOAD"
  ftp_local_path           = "CCMS_PRD_Eckoh/Outbound/"
  ftp_remote_path          = lower(local.environment) == "production" ? "/inbound/" : "/home/${local.ftp_test_user_secret_value["USER"]}/laa-ccms-outbound-${local.environment}-mp/outbound-lambda-runs/"
  ftp_bucket               = aws_s3_bucket.buckets["laa-ccms-outbound-${local.environment}-mp"].bucket
  env                      = local.environment
  secret_name              = "LAA-ftp-eckoh-inbound-ccms-${local.environment}"
  secret_arn               = aws_secretsmanager_secret.secrets["LAA-ftp-eckoh-inbound-ccms"].arn
  s3_bucket_ftp            = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key
  s3_object_ftp_client     = aws_s3_object.ftp_client.key
  #ftp_cron                     = "cron(0 10 * * ? *)"
  enabled_cron_in_environments = local.enable_cron_in_environments
}


# #LAA-ftp-eckoh-inbound-ccms
module "LAA-ftp-eckoh-inbound-ccms" {
  source                   = "./modules/ftp-lambda"
  lambda_name              = lower(format("LAA-ftp-eckoh-inbound-ccms-%s", local.environment))
  vpc_id                   = data.aws_vpc.shared.id
  subnet_ids               = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type        = "SFTP_DOWNLOAD"
  ftp_local_path           = "CCMS_PRD_Eckoh/Inbound/"
  ftp_remote_path          = lower(local.environment) == "production" ? "/outbound/" : "/home/${local.ftp_test_user_secret_value["USER"]}/laa-ccms-inbound-${local.environment}-mp/inbound-lambda-runs/"
  ftp_bucket               = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  env                      = local.environment
  secret_name              = "LAA-ftp-eckoh-inbound-ccms-${local.environment}"
  secret_arn               = aws_secretsmanager_secret.secrets["LAA-ftp-eckoh-inbound-ccms"].arn
  s3_bucket_ftp            = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key
  s3_object_ftp_client     = aws_s3_object.ftp_client.key
  #ftp_cron                     = "cron(0 10 * * ? *)"
  enabled_cron_in_environments = local.enable_cron_in_environments
}

# #LAA-ftp-rossendales-ccms-inbound
module "LAA-ftp-rossendales-ccms-inbound" {
  source                   = "./modules/ftp-lambda"
  lambda_name              = lower(format("LAA-ftp-rossendales-ccms-inbound-%s", local.environment))
  vpc_id                   = data.aws_vpc.shared.id
  subnet_ids               = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type        = "SFTP_DOWNLOAD"
  ftp_local_path           = "CCMS_PRD_Rossendales/Inbound/"
  ftp_remote_path          = lower(local.environment) == "production" ? "ccms/OutBound/" : "/home/${local.ftp_test_user_secret_value["USER"]}/laa-ccms-inbound-${local.environment}-mp/inbound-lambda-runs/"
  ftp_bucket               = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  env                      = local.environment
  secret_name              = "LAA-ftp-rossendales-ccms-inbound-${local.environment}"
  secret_arn               = aws_secretsmanager_secret.secrets["LAA-ftp-rossendales-ccms-inbound"].arn
  s3_bucket_ftp            = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key
  s3_object_ftp_client     = aws_s3_object.ftp_client.key
  #ftp_cron                     = "cron(0 10 * * ? *)"
  enabled_cron_in_environments = local.enable_cron_in_environments
}

# #LAA-ftp-1stlocate-ccms-inbound
module "LAA-ftp-1stlocate-ccms-inbound" {
  source                   = "./modules/ftp-lambda"
  lambda_name              = lower(format("LAA-ftp-1stlocate-ccms-inbound-%s", local.environment))
  vpc_id                   = data.aws_vpc.shared.id
  subnet_ids               = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type        = "SFTP_DOWNLOAD"
  ftp_local_path           = "CCMS_PRD_TDX_DECRYPTED/Inbound/"
  ftp_remote_path          = lower(local.environment) == "production" ? "/LAA_Direct/ToLAADirect/" : "/home/${local.ftp_test_user_secret_value["USER"]}/laa-ccms-inbound-${local.environment}-mp/inbound-lambda-runs/"
  ftp_port                 = "8022"
  ftp_bucket               = aws_s3_bucket.buckets["laa-ccms-inbound-${local.environment}-mp"].bucket
  env                      = local.environment
  secret_name              = "LAA-ftp-1stlocate-ccms-inbound-${local.environment}"
  secret_arn               = aws_secretsmanager_secret.secrets["LAA-ftp-1stlocate-ccms-inbound"].arn
  s3_bucket_ftp            = aws_s3_bucket.buckets["laa-ccms-ftp-lambda-${local.environment}-mp"].bucket
  s3_object_ftp_clientlibs = aws_s3_object.ftp_lambda_layer.key
  s3_object_ftp_client     = aws_s3_object.ftp_client.key
  #ftp_cron                     = "cron(0 10 * * ? *)"
  enabled_cron_in_environments = local.enable_cron_in_environments
} 