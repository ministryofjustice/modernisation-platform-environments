locals {
  operational_db_jdbc_connection_string = "jdbc:postgresql://${module.aurora_operational_db.rds_cluster_endpoints["static"]}:${local.operational_db_port}/${local.operational_db_default_database}"
  nomis_jdbc_connection_string          = "jdbc:oracle:thin:@${local.nomis_host}:${local.nomis_port}/${local.nomis_service_name}"
}

# Operational DataStore
resource "aws_glue_connection" "glue_operational_datastore_connection" {
  count           = local.create_glue_connection ? 1 : 0
  name            = "${local.project}-operational-datastore-connection"
  connection_type = "JDBC"

  connection_properties = {
    JDBC_CONNECTION_URL    = local.operational_db_jdbc_connection_string
    JDBC_DRIVER_CLASS_NAME = "org.postgresql.Driver"
    SECRET_ID              = data.aws_secretsmanager_secret.operational_db_secret.name
  }

  physical_connection_requirements {
    availability_zone      = data.aws_subnet.private_subnets_a.availability_zone
    security_group_id_list = [aws_security_group.glue_job_connection_sg.id]
    subnet_id              = data.aws_subnet.private_subnets_a.id
  }
}

# Nomis
resource "aws_glue_connection" "glue_nomis_connection" {
  count           = local.create_glue_connection ? 1 : 0
  name            = "${local.project}-nomis-connection"
  connection_type = "JDBC"

  connection_properties = {
    JDBC_CONNECTION_URL    = local.nomis_jdbc_connection_string
    JDBC_DRIVER_CLASS_NAME = "oracle.jdbc.driver.OracleDriver"
    SECRET_ID              = data.aws_secretsmanager_secret.nomis.name
  }

  physical_connection_requirements {
    availability_zone      = data.aws_subnet.private_subnets_a.availability_zone
    security_group_id_list = [aws_security_group.glue_job_connection_sg.id]
    subnet_id              = data.aws_subnet.private_subnets_a.id
  }
}

resource "aws_security_group" "glue_job_connection_sg" {
  #checkov:skip=CKV2_AWS_5
  name        = "${local.project}-glue-connection_sg"
  description = "Security group for glue jobs when using Glue Connections"
  vpc_id      = data.aws_vpc.shared.id

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