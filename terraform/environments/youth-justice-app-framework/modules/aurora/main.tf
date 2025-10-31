################################################################################
# RDS Aurora Module
################################################################################

module "aurora" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source = "terraform-aws-modules/rds-aurora/aws"
  # Do not use latest, pick a version so we don't unintentionally break things
  version = "9.4.0"

  # General
  name                = var.name #yjafrds01
  vpc_id              = var.vpc_id
  engine              = var.engine         #"aurora-postgresql"
  engine_version      = var.engine_version #16.1
  snapshot_identifier = var.snapshot_identifier

  # Engine Update settings
  allow_major_version_upgrade = true

  # Master user and Auth
  master_username                                        = var.master_username #"root"
  manage_master_user_password_rotation                   = true
  master_user_password_rotation_automatically_after_days = 30
  iam_database_authentication_enabled                    = var.iam_database_authentication_enabled

  # Subnet options
  create_db_subnet_group = true
  subnets                = var.database_subnets
  db_subnet_group_name   = var.database_subnet_group_name

  # Storage options
  allocated_storage = var.allocated_storage
  iops              = var.iops
  storage_type      = var.storage_type
  storage_encrypted = true

  # Instance options
  instance_class = var.db_cluster_instance_class
  instances      = var.instances

  # Iam Roles and features
  # todo, create redshift iam role in the redshift module and add it to rds
  iam_roles = var.iam_roles

  # Security Group
  create_security_group  = false #create separately for better readability
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Backup and maintenance
  apply_immediately            = true
  skip_final_snapshot          = var.skip_final_snapshot
  deletion_protection          = var.deletion_protection
  preferred_maintenance_window = var.preferred_maintenance_window
  backup_retention_period      = var.backup_retention_period

  # Monitoring
  create_monitoring_role            = true
  monitoring_interval               = 60
  enabled_cloudwatch_logs_exports   = ["postgresql"]
  create_cloudwatch_log_group       = true
  performance_insights_enabled      = var.performance_insights_enabled
  create_db_cluster_activity_stream = false #stopped on yjaf

  tags = var.create_sheduler ? merge(local.all_tags,
    {
      "schedule" = "lambda" #allows lambda scheduler to target this rds for overnight shutdown
    }
  ) : local.all_tags
}

#todo match yjaf production security group
resource "aws_security_group" "rds" {
  # checkov:skip=CKV2_AWS_5: Configured in Redshift cluster, Checkov not detecting reference.
  name_prefix = "RDS Postgres Security Group"
  description = "Controls access to the PostgreSQL RDS"
  vpc_id      = var.vpc_id

  tags = merge(local.all_tags,
    {
      Name = "RDS Postgres Security Group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}


# Retrieve the predefined Prefix List for S3 access
# TODO Consider replacing the hard coded regon in the prefix name with a variable.
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.eu-west-2.s3"
}
resource "aws_security_group_rule" "s3-access" {

  security_group_id = aws_security_group.rds.id
  type              = "egress"

  from_port       = 443
  to_port         = 443
  protocol        = "TCP"
  prefix_list_ids = [data.aws_prefix_list.s3.id]
  description     = "Enable exports to S3"

}


#todo additional users and their password rotation? can it be done?
