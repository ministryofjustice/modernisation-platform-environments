################################################################################
# DPR RDS - Parameter Group
################################################################################
module "dpr_rds_parameter_group" {
  source = "./modules/rds/parameter_group"

  count = local.is_dev_or_test ? 1 : 0

  create_db_parameter_group          = true
  db_parameter_group_use_name_prefix = false
  db_parameter_group_name            = local.dpr_rds_parameter_group_name
  db_parameter_group_family          = local.dpr_rds_parameter_group_family

  db_parameter_group_parameters = [
    {
      name         = "rds.logical_replication"
      value        = "1"
      apply_method = "pending-reboot"
    },
    {
      name         = "shared_preload_libraries"
      value        = "pglogical"
      apply_method = "pending-reboot"
    },
    {
      name         = "max_wal_size"
      value        = "1024"
      apply_method = "immediate"
    },
    {
      name         = "wal_sender_timeout"
      value        = "0"
      apply_method = "immediate"
    },
    {
      name         = "max_slot_wal_keep_size"
      value        = "40000"
      apply_method = "immediate"
    },
    {
      name         = "max_standby_streaming_delay"
      value        = "-1"
      apply_method = "immediate"
    },
    {
      name         = "max_standby_archive_delay"
      value        = "-1"
      apply_method = "immediate"
    }
  ]

  tags = merge(
    local.all_tags,
    {
      dpr-resource-group = "RDS"
      dpr-jira           = "DPR2-2072"
      dpr-resource-type  = "RDS Parameter Group"
      dpr-name           = local.dpr_rds_parameter_group_name
    }
  )
}

################################################################################
# DPR RDS - Database
################################################################################
module "dpr_rds_db" {
  source = "./modules/rds/postgres"

  count = local.is_dev_or_test ? 1 : 0

  enable_rds         = local.enable_dpr_rds_db
  create_rds_replica = local.create_rds_replica
  engine             = local.dpr_rds_engine
  engine_version     = local.dpr_rds_engine_version
  allocated_size     = local.dpr_rds_init_size
  max_allocated_size = local.dpr_rds_max_size
  subnets            = local.dpr_subnets
  vpc_id             = local.dpr_vpc
  kms                = local.rds_kms_arn
  name               = local.dpr_rds_db_identifier
  db_name            = local.dpr_rds_name
  db_instance_class  = local.dpr_rds_inst_class
  master_user        = jsondecode(data.aws_secretsmanager_secret_version.test_db[0].secret_string)["user"]
  storage_type       = local.dpr_rds_store_type
  ca_cert_identifier = "rds-ca-rsa2048-g1" # Expiry on June 16, 2026
  license_model      = "postgresql-license"

  allow_major_version_upgrade = true

  parameter_group = module.dpr_rds_parameter_group[0].parameter_group_name

  tags = merge(
    local.all_tags,
    {
      dpr-resource-group = "RDS"
      dpr-jira           = "DPR2-2072"
      dpr-resource-type  = "RDS Instance"
      dpr-name           = local.dpr_rds_name
    }
  )

  depends_on = [module.dpr_rds_parameter_group]
}