locals {
  operational_db_port             = 5432
  operational_db_default_database = "operational_db"

  name = "${local.project}-operational-db"

  create_db_parameter_group         = true
  create_db_cluster_parameter_group = true

  parameter_group_name         = "${local.name}-instance"
  cluster_parameter_group_name = null

  db_cluster_parameter_group_name = try(coalesce(local.cluster_parameter_group_name, local.name), null)
  db_parameter_group_name         = try(coalesce(local.parameter_group_name, local.name), null)

  operational_db_tags = merge(
    local.all_tags,
    {
      dpr-resource-group = "Operational-DB"
      dpr-resource-type  = "RDS"
      dpr-jira           = "DPR2-892"
      project            = local.project
      dpr-name           = "operational-db"
    }
  )

  operational_db_credentials = jsondecode(data.aws_secretsmanager_secret_version.operational_db_secret_version.secret_string)
}

################################################################################
# Operational DB - Parameter Group
################################################################################
module "operational_db_parameter_group" {
  source = "./modules/rds/parameter_group"

  create_db_parameter_group      = local.create_db_parameter_group
  db_parameter_group_name        = "${local.name}-instance"
  db_parameter_group_family      = "aurora-postgresql16"
  db_parameter_group_description = "${local.name} DB parameter group"
  db_parameter_group_parameters = [
    {
      name         = "log_min_duration_statement"
      value        = 4000
      apply_method = "immediate"
    },
    {
      name         = "shared_preload_libraries"
      value        = "pg_stat_statements,pg_cron"
      apply_method = "pending-reboot"
    },
    {
      name         = "cron.database_name"
      value        = local.operational_db_default_database
      apply_method = "pending-reboot"
    }
  ]

  tags = merge(
    local.operational_db_tags,
    {
      dpr-resource-type = "RDS Parameter Group"
    }
  )
}

################################################################################
# Operationa DB - Cluster Parameter Group
################################################################################
module "operational_db_cluster_parameter_group" {
  source = "./modules/rds/cluster_parameter_group"

  create_db_cluster_parameter_group      = local.create_db_cluster_parameter_group
  db_cluster_parameter_group_name        = local.db_cluster_parameter_group_name
  db_cluster_parameter_group_family      = "aurora-postgresql16"
  db_cluster_parameter_group_description = "${local.name} cluster parameter group"

  db_cluster_parameter_group_parameters = [
    {
      name         = "log_min_duration_statement"
      value        = 4000
      apply_method = "immediate"
    },
    {
      name         = "rds.force_ssl"
      value        = 1
      apply_method = "immediate"
    }
  ]
}

################################################################################
# Operational DB - RDS Aurora Cluster
################################################################################

module "aurora_operational_db" {
  source = "./modules/rds/aws-aurora/"

  name                        = "${local.name}-cluster"
  engine                      = "aurora-postgresql"
  engine_version              = "16"
  database_name               = "operational_db"
  manage_master_user_password = false
  master_username             = local.operational_db_credentials.username
  master_password             = local.operational_db_credentials.password
  instances = {
    1 = {
      identifier     = local.name
      instance_class = "db.t4g.medium"
    }
  }

  endpoints = {
    static = {
      identifier     = "operational-db-static-any-endpoint"
      type           = "ANY"
      static_members = [local.name]
      tags           = { Endpoint = "Operational-DB-Any" }
    }
  }

  ca_cert_identifier = "rds-ca-rsa2048-g1" # Updated on 29th July 2024

  vpc_id = data.aws_vpc.shared.id
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = [data.aws_vpc.dpr.cidr_block]
    }
    egress_example = {
      cidr_blocks = ["0.0.0.0/0"]
      description = "Egress to corporate printer closet"
    }
  }

  apply_immediately   = true
  skip_final_snapshot = true

  create_db_subnet_group = true
  subnets                = local.dpr_subnets

  db_parameter_group_name         = local.create_db_parameter_group ? module.operational_db_parameter_group.parameter_group_id : local.db_parameter_group_name
  db_cluster_parameter_group_name = local.create_db_cluster_parameter_group ? module.operational_db_cluster_parameter_group.db_cluster_parameter_group_id : local.db_cluster_parameter_group_name

  enabled_cloudwatch_logs_exports = ["postgresql"]
  create_cloudwatch_log_group     = true

  create_db_cluster_activity_stream     = false
  db_cluster_activity_stream_kms_key_id = local.operational_db_kms_id
  db_cluster_activity_stream_mode       = "async"

  tags = local.operational_db_tags

  depends_on = [module.operational_db_cluster_parameter_group, module.operational_db_parameter_group]
}
