locals {
  glue_connection_names = (local.environment == "development" ? [aws_glue_connection.glue_operational_datastore_connection[0].name] : [])
}

resource "aws_glue_connection" "glue_operational_datastore_connection" {
  count           = (local.environment == "development" ? 1 : 0)
  name            = "${local.project}-operational-datastore-connection"
  connection_type = "JDBC"

  connection_properties = {
    # This will be replaced by the details for the real Operational Data Store
    JDBC_CONNECTION_URL = "jdbc:postgresql://dpr2-834-instance-1.cja8lnnvvipo.eu-west-2.rds.amazonaws.com:5432/postgres"
    SECRET_ID           = data.aws_secretsmanager_secret.operational_datastore[0].name
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