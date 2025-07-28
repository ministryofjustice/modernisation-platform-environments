module "rds_export" {
  source = "github.com/ministryofjustice/terraform-rds-export?ref=4bc9d54fe3868720ab87d1b1a4e47e16fef1c0c3"

  kms_key_arn         = aws_kms_key.sns_kms.arn
  name                = "cafm"
  vpc_id              = module.vpc.vpc_id
  database_subnet_ids = module.vpc.private_subnets
  master_user_secret_id = aws_secretsmanager_secret.db_master_user_secret.arn

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
  kms_key_id = aws_kms_key.sns_kms.arn
}

module "endpoints" {
  # Commit has for v5.21.0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc//modules/vpc-endpoints?ref=507193ee659f6f0ecdd4a75107e59e2a6c1ac3cc"

  vpc_id                     = module.vpc.vpc_id
  create_security_group      = true
  security_group_description = "Managed by Terraform"
  security_group_tags        = { Name : "eu-west-1-dev" }
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
      tags                = { Name = "secretsmanager-eu-west-1-dev" }
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
  kms_key_arn = aws_kms_key.sns_kms.arn
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
