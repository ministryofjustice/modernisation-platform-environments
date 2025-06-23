

module "aurora" {
  source       = "./modules/aurora"
  project_name = local.project_name
  vpc_id       = data.aws_vpc.shared.id
  tags         = local.tags

  database_subnets           = local.data_subnet_list[*].id
  alb_route53_record_zone_id = data.aws_route53_zone.yjaf-inner.id


  name                       = "yjafrds01-cluster"
  azs                        = ["eu-west-2a", "eu-west-2b"]
  db_cluster_instance_class  = local.application_data.accounts[local.environment].database_instance_class
  database_subnet_group_name = "yjaf-db-subnet-group"
  alb_route53_record_name    = "db-yjafrds01"

  #one time restore from a shared snapshot #todo remove this post migration. Take from secrets manager
  snapshot_identifier = aws_secretsmanager_secret_version.snapshot_identifier.secret_string != "dummy" ? aws_secretsmanager_secret_version.snapshot_identifier.secret_string : local.application_data.accounts[local.environment].snapshot_identifier

  user_passwords_to_reset_rotated = ["postgres_rotated", "redshift_readonly"]
  user_passwords_to_reset_static  = ["ycs_team", "postgres"] # Need to be static as they are used in Tableau data sources.

  db_name        = "yjafrds01"
  aws_account_id = data.aws_caller_identity.current.account_id

  engine          = "aurora-postgresql"
  engine_version  = "16.6"
  master_username = "root"

  create_sheduler              = local.application_data.accounts[local.environment].create_rds_sheduler
  stop_aurora_cluster_schedule = "cron(00 00 ? * MON-FRI *)"
  performance_insights_enabled = true

  #pass in provider for creating records on central route53
  providers = {
    aws                       = aws
    aws.core-network-services = aws.core-network-services
  }
  kms_key_arn = module.kms.key_arn
  kms_key_id  = module.kms.key_id

  iam_roles = {
    rds_export_to_s3_role = {
      role_arn     = aws_iam_role.rds_export_to_s3_role.arn
      feature_name = "s3Export"
    }

  }

  rds_security_group_ingress = {
    "dummy_rule" = {
      from_port   = "5432"
      to_port     = "5432"
      protocol    = "tcp"
      description = "Allow PosgreSQL access from whole VPC"
      cidr_blocks = [data.aws_vpc.shared.cidr_block]
    }
  }
}

