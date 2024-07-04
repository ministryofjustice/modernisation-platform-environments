locals {
  glue_connection_names = (local.environment == "development" ? [aws_glue_connection.glue_operational_datastore_connection[0].name] : [])

  name   = "${local.project}-operational-db"

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
}

################################################################################
# RDS Aurora Cluster
################################################################################

module "aurora" {
  source = "./modules/rds/aws-aurora/"

  name            = "${local.name}-cluster"
  engine          = "aurora-postgresql"
  engine_version  = "16.2"
  master_username = "dpr-admin"
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
      static_members = ["${local.name}"]
      tags           = { Endpoint = "Operational-DB-Any" }
    }
  }

  vpc_id               = data.aws_vpc.shared.id
  db_subnet_group_name = data.aws_subnet.private_subnets_a.id
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
  db_cluster_parameter_group_name        = "${local.name}-cluster"
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
      },
      {
        name         = "shared_preload_libraries"
        value        = "pg_cron"
        apply_method = "pending-reboot"
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
    }
  ]

  enabled_cloudwatch_logs_exports = ["postgresql"]
  create_cloudwatch_log_group     = true

  create_db_cluster_activity_stream     = true
  # db_cluster_activity_stream_kms_key_id = module.kms.key_id
  db_cluster_activity_stream_mode       = "async"

  tags = local.operational_db_tags
}

resource "aws_glue_connection" "glue_operational_datastore_connection" {
  count           = (local.environment == "development" ? 1 : 0)
  name            = "${local.project}-operational-datastore-connection"
  connection_type = "JDBC"

  connection_properties = {
    # This will be replaced by the details for the real Operational Data Store
    JDBC_CONNECTION_URL    = "jdbc:postgresql://dpr2-834-instance-1.cja8lnnvvipo.eu-west-2.rds.amazonaws.com:5432/postgres"
    JDBC_DRIVER_CLASS_NAME = "org.postgresql.Driver"
    SECRET_ID              = data.aws_secretsmanager_secret.operational_datastore[0].name
  }

  physical_connection_requirements {
    availability_zone      = data.aws_subnet.private_subnets_a.availability_zone
    security_group_id_list = [aws_security_group.glue_operational_datastore_connection_sg[0].id]
    subnet_id              = data.aws_subnet.private_subnets_a.id
  }
}

resource "aws_security_group" "glue_operational_datastore_connection_sg" {
  count       = (local.environment == "development" ? 1 : 0)
  name        = "${local.project}-operational-datastore-connection_sg"
  description = "Security group to allow glue access to Operational Datastore via JDBC Connection"
  vpc_id      = data.aws_vpc.shared.id

  # This SG is attached to the Glue connection and should also be attached to the Operational Datastore RDS
  # See https://docs.aws.amazon.com/glue/latest/dg/setup-vpc-for-glue-access.html

  # A self-referencing inbound rule for all TCP ports to enable AWS Glue to communicate between its components
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "TCP"
    self        = true
    description = "Security Group can Ingress to itself on all ports - required for Glue to communicate with itself"
  }

  # Allow all traffic out
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all traffic out from this Security Group"
  }
}