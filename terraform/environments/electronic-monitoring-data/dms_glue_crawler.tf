resource "aws_glue_connection" "glue_rds_sqlserver_db_connection" {
  count = local.is-production || local.is-development ? 1 : 0
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:sqlserver://${aws_db_instance.database_2022[0].endpoint}"
    PASSWORD            = aws_secretsmanager_secret_version.db_password[0].secret_string
    USERNAME            = "admin"
  }

  name = "glue-rds-sqlserver-db-conn-tf"

  physical_connection_requirements {
    security_group_id_list = [aws_security_group.glue_rds_conn_security_group.id]
    subnet_id              = data.aws_subnet.private_subnets_c.id
    availability_zone      = data.aws_subnet.private_subnets_c.availability_zone
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "RDS-MSSQLServer JDBC-Connection for Glue-Crawler",
    }
  )
}

resource "aws_glue_catalog_database" "rds_sqlserver_glue_catalog_db" {
  count = local.is-production || local.is-development ? 1 : 0
  name  = "rds_sqlserver_dms"
  # create_table_default_permission {
  #   permissions = ["SELECT"]

  #   principal {
  #     data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
  #   }
  # }
}

resource "aws_glue_crawler" "rds_sqlserver_db_glue_crawler" {
  count = local.is-production || local.is-development ? 1 : 0
  #checkov:skip=CKV_AWS_195
  name          = "rds-sqlserver-${aws_db_instance.database_2022[0].identifier}-tf"
  role          = aws_iam_role.dms_dv_glue_job_iam_role.arn
  database_name = aws_glue_catalog_database.rds_sqlserver_glue_catalog_db[0].name
  description   = "Crawler to fetch database names"
  #   table_prefix  = "your_table_prefix"

  jdbc_target {
    connection_name = aws_glue_connection.glue_rds_sqlserver_db_connection[0].name
    path            = "%"
  }
  tags = merge(
    local.tags,
    {
      Resource_Type = "RDS-SQLServer Glue-Crawler for DMS",
    }
  )

  # provisioner "local-exec" {
  #   command = "aws glue start-crawler --name ${self.name}"
  # }
}

resource "aws_glue_trigger" "rds_sqlserver_db_glue_trigger" {
  count = local.is-production || local.is-development ? 1 : 0
  name  = aws_glue_crawler.rds_sqlserver_db_glue_crawler[0].name
  type  = "ON_DEMAND"

  actions {
    crawler_name = aws_glue_crawler.rds_sqlserver_db_glue_crawler[0].name
  }
}
