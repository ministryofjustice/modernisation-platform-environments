resource "aws_glue_connection" "glue_operational_datastore_connection" {
  name            = "${local.project}-operational-datastore-connection"
  connection_type = "JDBC"

  connection_properties = {
    # This will be replaced by the details for the real Operational Data Store
    JDBC_CONNECTION_URL = "jdbc:postgresql://dpr2-834-instance-1.cja8lnnvvipo.eu-west-2.rds.amazonaws.com:5432/postgres"
    SECRET_ID           = data.aws_secretmanager_secret.operational_datastore.name
  }

  physical_connection_requirements {
    availability_zone = data.aws_subnet.private_subnets_a.availability_zone
    security_group_id_list = [aws_security_group.glue_vpc_access_connection_sg[0].id]
    subnet_id         = data.aws_subnet.private_subnets_a.id
  }
}