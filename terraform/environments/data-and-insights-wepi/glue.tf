locals {
  redshift_dns  = aws_redshift_cluster.wepi_redshift_cluster.dns_name
  redshift_port = aws_redshift_cluster.wepi_redshift_cluster.port
  redshift_db   = aws_redshift_cluster.wepi_redshift_cluster.database_name
}

resource "aws_glue_connection" "wepi_glue_conn_redshift" {
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:redshift://${local.redshift_dns}:${local.redshift_port}/${local.redshift_db}"
    PASSWORD            = aws_secretsmanager_secret_version.wepi_redshift_admin_pw.secret_string
    USERNAME            = aws_redshift_cluster.wepi_redshift_cluster.master_username
  }

  name = "wepi-redshift-${local.environment}-conn"
  physical_connection_requirements {
    security_group_id_list = ["${aws_security_group.wepi_sg_allow_redshift.id}"]
    subnet_id              = data.aws_subnet.data_subnets_a.id
  }

  tags = local.tags
}