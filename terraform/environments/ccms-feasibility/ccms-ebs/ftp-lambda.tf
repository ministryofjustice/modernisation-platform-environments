locals {
  ftp_lambda_secret_names = [
    "ccms-ftp-allpay-inbound",
    "ccms-ftp-rossendales-inbound",
    "ccms-ftp-eckoh-inbound",
    "ccms-ftp-1stlocate-inbound",
    "ccms-ftp-xerox-outbound",
  ]

  # No CloudWatch schedule is enabled for feasibility - these Lambdas are deployed for ad hoc/manual invocation only.
  ftp_lambda_enabled_cron_in_environments = []

  # Non-prod test target: the FTP box mounts the same inbound/outbound buckets via s3fs and exposes them under this SSH test user's home dir
  ftp_test_user_name = "ccmsftptest"

  ftp_lambda_outbound_remote_path_nonprod = "/home/${local.ftp_test_user_name}/${module.s3_outbound.bucket.id}/outbound-lambda-runs/"
  ftp_lambda_inbound_remote_path_nonprod  = "/home/${local.ftp_test_user_name}/${module.s3_inbound.bucket.id}/inbound-lambda-runs/"
}

### secrets for ftp user and password

resource "aws_secretsmanager_secret" "ftp_lambda_secrets" {
  for_each = toset(local.ftp_lambda_secret_names)

  name = each.value

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "ftp_lambda_secrets" {
  for_each = aws_secretsmanager_secret.ftp_lambda_secrets

  secret_id = each.value.id
  secret_string = jsonencode({
    HOST          = ""
    USER          = ""
    PASSWORD      = ""
    SSH_KEY       = ""
    SLACK_WEBHOOK = ""
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Non-prod test target secret: SSH login for the FTP box's own test user

resource "aws_secretsmanager_secret" "ftp_test_user" {
  name        = "ccms-ftp-test-user"
  description = "SSH login for the FTP box's own test user, used as the non-prod SFTP target for ad hoc ftp-lambda test runs"

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "ftp_test_user" {
  secret_id = aws_secretsmanager_secret.ftp_test_user.id
  secret_string = jsonencode({
    HOST          = module.ftp.private_ip
    USER          = local.ftp_test_user_name
    PASSWORD      = ""
    SLACK_WEBHOOK = ""
  })
  lifecycle {
    ignore_changes = [secret_string]
  }
}

module "allpay_ftp_lambda_outbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/0d7e3b9
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ftp?ref=0d7e3b9"

  lambda_name                  = "ccms-ftp-allpay-outbound-${local.env_label}"
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_UPLOAD"
  ftp_local_path               = "CCMS_PRD_Allpay/Outbound/"
  ftp_remote_path              = local.is-production ? "/Inbound/" : local.ftp_lambda_outbound_remote_path_nonprod
  ftp_bucket                   = module.s3_outbound.bucket.id
  env                          = local.environment
  secret_name                  = "ccms-ftp-allpay-inbound"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["ccms-ftp-allpay-inbound"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
  tags                         = local.tags
}

module "allpay_ftp_lambda_inbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/0d7e3b9
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ftp?ref=0d7e3b9"

  lambda_name                  = "ccms-ftp-allpay-inbound-${local.env_label}"
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_DOWNLOAD"
  ftp_local_path               = "CCMS_PRD_Allpay/Inbound/"
  ftp_remote_path              = local.is-production ? "/Outbound/" : local.ftp_lambda_inbound_remote_path_nonprod
  ftp_bucket                   = module.s3_inbound.bucket.id
  env                          = local.environment
  secret_name                  = "ccms-ftp-allpay-inbound"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["ccms-ftp-allpay-inbound"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
  tags                         = local.tags
}

module "xerox_ftp_lambda_outbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/0d7e3b9
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ftp?ref=0d7e3b9"

  lambda_name                  = "ccms-ftp-xerox-outbound-${local.env_label}"
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_UPLOAD"
  ftp_local_path               = "CCMS_PRD_DST/Outbound/"
  ftp_remote_path              = local.is-production ? "/Production/outbound/CCMS/" : local.ftp_lambda_outbound_remote_path_nonprod
  ftp_file_types               = "zip"
  ftp_bucket                   = module.s3_outbound.bucket.id
  env                          = local.environment
  secret_name                  = "ccms-ftp-xerox-outbound"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["ccms-ftp-xerox-outbound"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(5 5 * * ? *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
  tags                         = local.tags
}

module "xerox_ftp_lambda_outbound_peterborough" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/0d7e3b9
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ftp?ref=0d7e3b9"

  lambda_name                  = "ccms-ftp-xerox-outbound-peterborough-${local.env_label}"
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_UPLOAD"
  ftp_local_path               = "CCMS_PRD_DST/Outbound/Peterborough/"
  ftp_remote_path              = local.is-production ? "/Production/outbound/PETER/" : local.ftp_lambda_outbound_remote_path_nonprod
  ftp_bucket                   = module.s3_outbound.bucket.id
  env                          = local.environment
  secret_name                  = "ccms-ftp-xerox-outbound"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["ccms-ftp-xerox-outbound"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
  tags                         = local.tags
}

module "eckoh_ftp_lambda_outbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/0d7e3b9
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ftp?ref=0d7e3b9"

  lambda_name                  = "ccms-ftp-eckoh-outbound-${local.env_label}"
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_UPLOAD"
  ftp_local_path               = "CCMS_PRD_Eckoh/Outbound/"
  ftp_remote_path              = local.is-production ? "/inbound/" : local.ftp_lambda_outbound_remote_path_nonprod
  ftp_bucket                   = module.s3_outbound.bucket.id
  env                          = local.environment
  secret_name                  = "ccms-ftp-eckoh-inbound"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["ccms-ftp-eckoh-inbound"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
  tags                         = local.tags
}

module "eckoh_ftp_lambda_inbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/0d7e3b9
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ftp?ref=0d7e3b9"

  lambda_name                  = "ccms-ftp-eckoh-inbound-${local.env_label}"
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_DOWNLOAD"
  ftp_local_path               = "CCMS_PRD_Eckoh/Inbound/"
  ftp_remote_path              = local.is-production ? "/outbound/" : local.ftp_lambda_inbound_remote_path_nonprod
  ftp_bucket                   = module.s3_inbound.bucket.id
  env                          = local.environment
  secret_name                  = "ccms-ftp-eckoh-inbound"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["ccms-ftp-eckoh-inbound"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
  tags                         = local.tags
}

module "rossendales_ftp_lambda_inbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/0d7e3b9
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ftp?ref=0d7e3b9"

  lambda_name                  = "ccms-ftp-rossendales-inbound-${local.env_label}"
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_DOWNLOAD"
  ftp_local_path               = "CCMS_PRD_Rossendales/Inbound/"
  ftp_remote_path              = local.is-production ? "ccms/OutBound/" : local.ftp_lambda_inbound_remote_path_nonprod
  ftp_bucket                   = module.s3_inbound.bucket.id
  env                          = local.environment
  secret_name                  = "ccms-ftp-rossendales-inbound"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["ccms-ftp-rossendales-inbound"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
  tags                         = local.tags
}

module "onestlocate_ftp_lambda_inbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/0d7e3b9
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ftp?ref=0d7e3b9"

  lambda_name                  = "ccms-ftp-1stlocate-inbound-${local.env_label}"
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_DOWNLOAD"
  ftp_local_path               = "CCMS_PRD_TDX_DECRYPTED/Inbound/"
  ftp_remote_path              = local.is-production ? "/LAA_Direct/ToLAADirect/" : local.ftp_lambda_inbound_remote_path_nonprod
  ftp_port                     = "8022"
  ftp_bucket                   = module.s3_inbound.bucket.id
  env                          = local.environment
  secret_name                  = "ccms-ftp-1stlocate-inbound"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["ccms-ftp-1stlocate-inbound"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
  tags                         = local.tags
}
