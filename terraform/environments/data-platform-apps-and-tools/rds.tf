resource "random_password" "datahub_rds" {
  length  = 32
  special = false
}

data "aws_eks_cluster" "apps_and_tools" {
  name = "apps-tools-${local.environment}"
}

data "aws_iam_openid_connect_provider" "apps_and_tools" {
  url = data.aws_eks_cluster.apps_and_tools.identity[0].oidc[0].issuer
}

data "aws_vpc" "dedicated" {
  tags = {
    Name = "${local.application_name}-${local.environment}"
  }
}

data "aws_subnets" "dedicated" {
  for_each = toset(["db", "private", "public"])
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.dedicated.id]
  }
  filter {
    name   = "tag:Name"
    values = ["${local.application_name}-${local.environment}-${each.value}-*"]
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.dedicated["private"].ids)
  id       = each.value
}

data "aws_db_subnet_group" "db_subnet_group" {
  name = "${local.application_name}-${local.environment}"
}

data "aws_iam_policy_document" "datahub" {
  statement {
    sid       = "AllowAssumeRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = formatlist("arn:aws:iam::%s:role/${local.environment_configuration.datahub_role}", local.environment_configuration.datahub_target_accounts)
  }
}

resource "aws_iam_policy" "datahub" {
  name        = "datahub-policy"
  path        = "/"
  description = "Datahub Policy for Data Ingestion"
  policy      = data.aws_iam_policy_document.datahub.json
}

module "datahub_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "datahub"
  role_policy_arns = {
    datahub-ingestion = aws_iam_policy.datahub.arn
  }
  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.apps_and_tools.arn
      namespace_service_accounts = ["datahub:datahub-datahub-frontend"]
    }
  }
}

module "datahub_rds_security_group" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name = "datahub-rds"

  vpc_id = data.aws_vpc.dedicated.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = join(",", [for subnet in data.aws_subnet.private : subnet.cidr_block])
    },
  ]

  tags = local.tags
}

module "datahub_rds_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.0"

  aliases               = ["rds/datahub"]
  description           = "Datahub RDS"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "datahub_rds" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "datahub"

  engine               = "postgres"
  engine_version       = "15"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = "db.r6g.xlarge"

  ca_cert_identifier = "rds-ca-rsa2048-g1"

  allocated_storage     = 128
  max_allocated_storage = 512

  multi_az               = true
  db_subnet_group_name   = data.aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [module.datahub_rds_security_group.security_group_id]

  username                    = "datahub"
  db_name                     = "datahub"
  manage_master_user_password = false
  password                    = random_password.datahub_rds.result
  kms_key_id                  = module.datahub_rds_kms.key_arn

  parameters = [
    {
      name  = "rds.force_ssl"
      value = 1
    },
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_hostname"
      value = 1
    },
    {
      name  = "log_connections"
      value = 1
    }
  ]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 7
  deletion_protection     = true

  apply_immediately = true

  performance_insights_enabled = true

  create_monitoring_role          = true
  monitoring_role_use_name_prefix = true
  monitoring_role_name            = "datahub-rds-monitoring"
  monitoring_role_description     = "Enhanced Monitoring for Datahub RDS"
  monitoring_interval             = 30
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  skip_final_snapshot = true

  tags = local.tags
}