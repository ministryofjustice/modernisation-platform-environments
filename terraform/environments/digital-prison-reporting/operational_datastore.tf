locals {
  operational_db_port             = 5432
  operational_db_default_database = "operational_db"

  name = "${local.project}-operational-db"

  operational_db_tags = merge(
    local.all_tags,
    {
      Resource_Group = "Operational-DB"
      Resource_Type  = "RDS"
      Jira           = "DPR2-892"
      project        = local.project
      Name           = "operational-db"
    }
  )

  operational_db_credentials = jsondecode(data.aws_secretsmanager_secret_version.operational_db_secret_version.secret_string)
}

################################################################################
# Operationa DB - RDS Aurora Cluster
################################################################################

module "aurora_operational_db" {
  source = "./modules/rds/aws-aurora/"

  name                        = "${local.name}-cluster"
  engine                      = "aurora-postgresql"
  engine_version              = "16.6"
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

  create_db_cluster_parameter_group      = true
  create_db_subnet_group                 = true
  subnets                                = local.dpr_subnets
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

  create_db_parameter_group      = true
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

  enabled_cloudwatch_logs_exports = ["postgresql"]
  create_cloudwatch_log_group     = true

  create_db_cluster_activity_stream     = false
  db_cluster_activity_stream_kms_key_id = local.operational_db_kms_id
  db_cluster_activity_stream_mode       = "async"

  tags = local.operational_db_tags
}
