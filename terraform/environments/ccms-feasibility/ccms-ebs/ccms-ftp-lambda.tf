locals {
  ftp_lambda_secret_names = [
    "LAA-ftp-allpay-inbound-ccms",
    "LAA-ftp-rossendales-ccms-inbound",
    "LAA-ftp-eckoh-inbound-ccms",
    "LAA-ftp-1stlocate-ccms-inbound",
    "LAA-ftp-xerox-outbound",
  ]

  # No CloudWatch schedule is enabled for feasibility in any environment -
  # these Lambdas are deployed for ad hoc/manual invocation only.
  ftp_lambda_enabled_cron_in_environments = []

  # Feasibility has no non-prod test SFTP target standing in for partner
  # servers (unlike the original, which points non-prod at a self-hosted
  # test user's home dir). These are placeholders until a real target
  # exists; the production-path literals match the real partner paths.
  ftp_lambda_outbound_remote_path_nonprod = "/outbound-lambda-runs/"
  ftp_lambda_inbound_remote_path_nonprod  = "/inbound-lambda-runs/"
}

### secrets for ftp user and password
resource "aws_secretsmanager_secret" "ftp_lambda_secrets" {
  for_each = toset(local.ftp_lambda_secret_names)

  name = "${each.value}-${local.env_label}"

  tags = local.tags
}

module "allpay_ftp_lambda_outbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/REPLACE_WITH_MERGED_SHA
  source = "/Users/sahid.khan/Documents/repos/laa-ccms-terraform-modules/modules/ftp"

  lambda_name                  = lower(format("LAA-ftp-allpay-outbound-ccms-%s", local.env_label))
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_UPLOAD"
  ftp_local_path               = "CCMS_PRD_Allpay/Outbound/"
  ftp_remote_path              = local.is-production ? "/Inbound/" : local.ftp_lambda_outbound_remote_path_nonprod
  ftp_bucket                   = module.s3_outbound.bucket.id
  env                          = local.environment
  secret_name                  = "LAA-ftp-allpay-inbound-ccms-${local.env_label}"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["LAA-ftp-allpay-inbound-ccms"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
}

module "allpay_ftp_lambda_inbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/REPLACE_WITH_MERGED_SHA
  source = "/Users/sahid.khan/Documents/repos/laa-ccms-terraform-modules/modules/ftp"

  lambda_name                  = lower(format("LAA-ftp-allpay-inbound-ccms-%s", local.env_label))
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_DOWNLOAD"
  ftp_local_path               = "CCMS_PRD_Allpay/Inbound/"
  ftp_remote_path              = local.is-production ? "/Outbound/" : local.ftp_lambda_inbound_remote_path_nonprod
  ftp_bucket                   = module.s3_inbound.bucket.id
  env                          = local.environment
  secret_name                  = "LAA-ftp-allpay-inbound-ccms-${local.env_label}"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["LAA-ftp-allpay-inbound-ccms"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
}

module "xerox_ftp_lambda_outbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/REPLACE_WITH_MERGED_SHA
  source = "/Users/sahid.khan/Documents/repos/laa-ccms-terraform-modules/modules/ftp"

  lambda_name                  = lower(format("LAA-ftp-xerox-ccms-outbound-%s", local.env_label))
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_UPLOAD"
  ftp_local_path               = "CCMS_PRD_DST/Outbound/"
  ftp_remote_path              = local.is-production ? "/Production/outbound/CCMS/" : local.ftp_lambda_outbound_remote_path_nonprod
  ftp_file_types               = "zip"
  ftp_bucket                   = module.s3_outbound.bucket.id
  env                          = local.environment
  secret_name                  = "LAA-ftp-xerox-outbound-${local.env_label}"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["LAA-ftp-xerox-outbound"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(5 5 * * ? *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
}

module "xerox_ftp_lambda_outbound_peterborough" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/REPLACE_WITH_MERGED_SHA
  source = "/Users/sahid.khan/Documents/repos/laa-ccms-terraform-modules/modules/ftp"

  lambda_name                  = lower(format("LAA-ftp-xerox-ccms-outbound-peterborough-%s", local.env_label))
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_UPLOAD"
  ftp_local_path               = "CCMS_PRD_DST/Outbound/Peterborough/"
  ftp_remote_path              = local.is-production ? "/Production/outbound/PETER/" : local.ftp_lambda_outbound_remote_path_nonprod
  ftp_bucket                   = module.s3_outbound.bucket.id
  env                          = local.environment
  secret_name                  = "LAA-ftp-xerox-outbound-${local.env_label}"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["LAA-ftp-xerox-outbound"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
}

module "eckoh_ftp_lambda_outbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/REPLACE_WITH_MERGED_SHA
  source = "/Users/sahid.khan/Documents/repos/laa-ccms-terraform-modules/modules/ftp"

  lambda_name                  = lower(format("LAA-ftp-eckoh-outbound-ccms-%s", local.env_label))
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_UPLOAD"
  ftp_local_path               = "CCMS_PRD_Eckoh/Outbound/"
  ftp_remote_path              = local.is-production ? "/inbound/" : local.ftp_lambda_outbound_remote_path_nonprod
  ftp_bucket                   = module.s3_outbound.bucket.id
  env                          = local.environment
  secret_name                  = "LAA-ftp-eckoh-inbound-ccms-${local.env_label}"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["LAA-ftp-eckoh-inbound-ccms"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
}

module "eckoh_ftp_lambda_inbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/REPLACE_WITH_MERGED_SHA
  source = "/Users/sahid.khan/Documents/repos/laa-ccms-terraform-modules/modules/ftp"

  lambda_name                  = lower(format("LAA-ftp-eckoh-inbound-ccms-%s", local.env_label))
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_DOWNLOAD"
  ftp_local_path               = "CCMS_PRD_Eckoh/Inbound/"
  ftp_remote_path              = local.is-production ? "/outbound/" : local.ftp_lambda_inbound_remote_path_nonprod
  ftp_bucket                   = module.s3_inbound.bucket.id
  env                          = local.environment
  secret_name                  = "LAA-ftp-eckoh-inbound-ccms-${local.env_label}"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["LAA-ftp-eckoh-inbound-ccms"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
}

module "rossendales_ftp_lambda_inbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/REPLACE_WITH_MERGED_SHA
  source = "/Users/sahid.khan/Documents/repos/laa-ccms-terraform-modules/modules/ftp"

  lambda_name                  = lower(format("LAA-ftp-rossendales-ccms-inbound-%s", local.env_label))
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_DOWNLOAD"
  ftp_local_path               = "CCMS_PRD_Rossendales/Inbound/"
  ftp_remote_path              = local.is-production ? "ccms/OutBound/" : local.ftp_lambda_inbound_remote_path_nonprod
  ftp_bucket                   = module.s3_inbound.bucket.id
  env                          = local.environment
  secret_name                  = "LAA-ftp-rossendales-ccms-inbound-${local.env_label}"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["LAA-ftp-rossendales-ccms-inbound"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
}

module "onestlocate_ftp_lambda_inbound" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/REPLACE_WITH_MERGED_SHA
  source = "/Users/sahid.khan/Documents/repos/laa-ccms-terraform-modules/modules/ftp"

  lambda_name                  = lower(format("LAA-ftp-1stlocate-ccms-inbound-%s", local.env_label))
  vpc_id                       = data.aws_vpc.shared.id
  subnet_ids                   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  ftp_transfer_type            = "SFTP_DOWNLOAD"
  ftp_local_path               = "CCMS_PRD_TDX_DECRYPTED/Inbound/"
  ftp_remote_path              = local.is-production ? "/LAA_Direct/ToLAADirect/" : local.ftp_lambda_inbound_remote_path_nonprod
  ftp_port                     = "8022"
  ftp_bucket                   = module.s3_inbound.bucket.id
  env                          = local.environment
  secret_name                  = "LAA-ftp-1stlocate-ccms-inbound-${local.env_label}"
  secret_arn                   = aws_secretsmanager_secret.ftp_lambda_secrets["LAA-ftp-1stlocate-ccms-inbound"].arn
  s3_bucket_ftp                = module.s3_ftp_lambda.bucket.id
  s3_bucket_layer_ftp          = module.s3_ftp_lambda.bucket.id
  s3_object_ftp_clientlibs     = "lambda_delivery/ftp_lambda_layer/ftp_lambda_layer.zip"
  s3_object_ftp_client         = "lambda/ftp-client-v3.1.zip"
  ftp_cron                     = "cron(0 10 ? * MON-FRI *)"
  enabled_cron_in_environments = local.ftp_lambda_enabled_cron_in_environments
}
