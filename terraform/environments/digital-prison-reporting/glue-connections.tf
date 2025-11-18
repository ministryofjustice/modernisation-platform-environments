locals {
  operational_db_jdbc_connection_string = "jdbc:postgresql://${module.aurora_operational_db.rds_cluster_endpoints["static"]}:${local.operational_db_port}/${local.operational_db_default_database}"
  nomis_jdbc_connection_string          = "jdbc:oracle:thin:@//${local.nomis_host}:${local.nomis_port}/${local.nomis_service_name}"

  dpr_test_connection_string = try("jdbc:postgresql://${module.dpr_rds_db[0].rds_host}:${module.dpr_rds_db[0].rds_port}/${jsondecode(data.aws_secretsmanager_secret_version.test_db[0].secret_string)["db_name"]}", "")

  dps_endpoint = {
    for item in local.dps_domains_list :
    item => jsondecode(data.aws_secretsmanager_secret_version.dps[item].secret_string)["endpoint"]
  }
  dps_port = {
    for item in local.dps_domains_list :
    item => jsondecode(data.aws_secretsmanager_secret_version.dps[item].secret_string)["port"]
  }
  dps_database = {
    for item in local.dps_domains_list :
    item => jsondecode(data.aws_secretsmanager_secret_version.dps[item].secret_string)["db_name"]
  }
  dps_connection_string = {
    for item in local.dps_domains_list :
    item => "jdbc:postgresql://${local.dps_endpoint[item]}:${local.dps_port[item]}/${local.dps_database[item]}"
  }
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

# All DPS connections
resource "aws_glue_connection" "glue_dps_connection" {
  for_each        = local.create_glue_connection ? toset(local.dps_domains_list) : []
  name            = "${local.project}-${each.value}-connection"
  connection_type = "JDBC"

  connection_properties = {
    JDBC_CONNECTION_URL    = local.dps_connection_string[each.value]
    JDBC_DRIVER_CLASS_NAME = "org.postgresql.Driver"
    SECRET_ID              = aws_secretsmanager_secret.dps[each.value].name
  }

  physical_connection_requirements {
    availability_zone      = data.aws_subnet.private_subnets_a.availability_zone
    security_group_id_list = [aws_security_group.glue_job_connection_sg.id]
    subnet_id              = data.aws_subnet.private_subnets_a.id
  }
}

resource "aws_glue_connection" "glue_dpr_test_connection" {
  count           = (local.create_glue_connection && local.is_dev_or_test) ? 1 : 0
  name            = "${local.project}-dps-test-db-connection"
  connection_type = "JDBC"

  connection_properties = {
    JDBC_CONNECTION_URL    = local.dpr_test_connection_string
    JDBC_DRIVER_CLASS_NAME = "org.postgresql.Driver"
    SECRET_ID              = aws_secretsmanager_secret.dpr-test[0].name
  }

  physical_connection_requirements {
    availability_zone      = data.aws_subnet.private_subnets_a.availability_zone
    security_group_id_list = [aws_security_group.glue_job_connection_sg.id]
    subnet_id              = data.aws_subnet.private_subnets_a.id
  }
}

resource "aws_security_group" "glue_job_connection_sg" {
  #checkov:skip=CKV2_AWS_5
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
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
