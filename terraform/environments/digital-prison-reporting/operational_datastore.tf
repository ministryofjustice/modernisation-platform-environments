locals {
  glue_connection_names                 = (local.environment == "development" ? [aws_glue_connection.glue_operational_datastore_connection[0].name] : [])
  operational_db_port                   = 5432
  operational_db_jdbc_connection_string = "jdbc:postgresql://dpr2-834-instance-1.cja8lnnvvipo.eu-west-2.rds.amazonaws.com:${local.operational_db_port}/postgres"

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

  operational_db_credentials = jsondecode(data.aws_secretsmanager_secret_version.operational_db_secret_version.secret_string)
}

################################################################################
# RDS Aurora Cluster
################################################################################

module "aurora" {
  source = "./modules/rds/aws-aurora/"

  name                        = "${local.name}-cluster"
  engine                      = "aurora-postgresql"
  engine_version              = "16.2"
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
      static_members = ["${local.name}"]
      tags           = { Endpoint = "Operational-DB-Any" }
    }
  }

  vpc_id               = data.aws_vpc.shared.id
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
      value        = "pg_stat_statements, pg_cron"
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

resource "aws_glue_connection" "glue_operational_datastore_connection" {
  count           = (local.environment == "development" ? 1 : 0)
  name            = "${local.project}-operational-datastore-connection"
  connection_type = "JDBC"

  connection_properties = {
    # This will be replaced by the details for the real Operational Data Store
    JDBC_CONNECTION_URL    = local.operational_db_jdbc_connection_string
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

# This SG should be attached to the Operational DataStore to allow the transfer component lambda to run migrations
resource "aws_security_group" "allow_lambda_ingress_to_operational_datastore" {
  count = local.environment == "development" && local.enable_generic_lambda_sg ? 1 : 0

  name        = "${local.project}-operational-datastore-allow-lambda-ingress_sg"
  description = "Security group to allow ingress to Operational Datastore from transfer component lambda"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port = local.operational_db_port
    to_port   = local.operational_db_port
    protocol  = "tcp"
    security_groups = [aws_security_group.lambda_generic[0].id]
  }
}
