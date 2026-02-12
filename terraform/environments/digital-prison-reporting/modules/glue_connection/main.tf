resource "aws_glue_connection" "data_domain_redshift" {
  count = var.create_connection ? 1 : 0

  connection_properties = {
    JDBC_CONNECTION_URL = var.connection_url
    PASSWORD            = var.password
    USERNAME            = var.username
  }

  name        = var.name
  description = var.description

  # Optional

  physical_connection_requirements {
    security_group_id_list = var.security_groups
    subnet_id              = var.subnet
    availability_zone      = var.availability_zone
  }
}