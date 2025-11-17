module "csv_export" {
  source = "github.com/ministryofjustice/terraform-csv-to-parquet-athena?ref=0e258f4b5554e7d67069ca5d88138948a4357e66"
  providers = {
    aws.bucket-replication = aws
  }

  region_replication = "eu-west-2"
  kms_key_arn        = aws_kms_key.shared_kms_key.arn
  name               = "concept"
  load_mode          = "overwrite"
  environment        = local.environment_shorthand
  tags = {
    business-unit = "Property"
    application   = "cafm"
    is-production = "false"
    owner         = "shanmugapriya.basker@justice.gov.uk"
  }
}

module "rds_export" {
  source = "github.com/ministryofjustice/terraform-rds-export?ref=e48992e9a69c95bd3ccf2b8affbbd8d7b53ddeb4"
  providers = {
    aws = aws
  }

  kms_key_arn              = aws_kms_key.shared_kms_key.arn
  name                     = "planetfm"
  db_name                  = "planetfm_${local.environment_shorthand}"
  database_refresh_mode    = "full"
  output_parquet_file_size = 200
  max_concurrency          = 5
  environment              = local.environment_shorthand
  vpc_id                   = module.vpc.vpc_id
  database_subnet_ids      = module.vpc.private_subnets
  master_user_secret_id    = aws_secretsmanager_secret.db_master_user_secret.arn

  tags = {
    business-unit = "Property"
    application   = local.application_name
    is-production = "false"
    owner         = "shanmugapriya.basker@justice.gov.uk"
  }
}

resource "aws_secretsmanager_secret" "db_master_user_secret" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  name       = "cafm-database-master-user-secret"
  kms_key_id = aws_kms_key.shared_kms_key.arn
}

module "endpoints" {
  # Commit has for v5.21.0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc//modules/vpc-endpoints?ref=507193ee659f6f0ecdd4a75107e59e2a6c1ac3cc"

  vpc_id                     = module.vpc.vpc_id
  create_security_group      = true
  security_group_description = "Managed by Terraform"
  security_group_tags        = { Name : "cafm-migration-rds-sg" }
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }
  endpoints = {
    secrets_manager = {
      service             = "secretsmanager"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
      tags                = { Name = "cafm-secretsmanager-endpoint" }
    }
    glue = {
      service             = "glue"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
      tags                = { Name = "cafm-glue-endpoint" }
    }
  }

  tags = { Name = "${local.application_name}-secrets-endpoint" }

}

module "server" {
  source      = "./modules/transfer_family/server"
  name        = "CAFM SFTP Server"
  environment = local.environment
}

# ------------------------
# Transfer User
# ------------------------
module "sftp_user" {
  source   = "./modules/transfer_family/users"
  for_each = local.environment_configuration.transfer_server_sftp_users

  user_name   = each.value.user_name
  server_id   = module.server.id
  s3_bucket   = each.value.s3_bucket
  kms_key_arn = aws_kms_key.shared_kms_key.arn
}


data "aws_ssm_parameter" "ssh_keys" {
  for_each = local.environment_configuration.transfer_server_sftp_users
  name     = each.value.ssm_key_name
}

# ------------------------
# SSH Key for SFTP Login
# ------------------------
module "sftp_ssh_key" {
  source   = "./modules/transfer_family/ssh_key"
  for_each = local.environment_configuration.transfer_server_sftp_users

  server_id    = module.server.id
  user_name    = each.key
  ssh_key_body = data.aws_ssm_parameter.ssh_keys[each.key].value

  depends_on = [module.sftp_user]
}
