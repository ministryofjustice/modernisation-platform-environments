resource "aws_glue_connection" "rds_sqlserver_db_glue_connection" {
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:sqlserver://${aws_db_instance.database_2022.endpoint}"
    PASSWORD            = aws_secretsmanager_secret_version.db_password.secret_string
    USERNAME            = "admin"
  }

  name = "rds-sqlserver-db-glue-conn-tf"

  physical_connection_requirements {
    security_group_id_list = [aws_security_group.db.id]
    subnet_id              = data.aws_subnet.private_subnets_c.id
    # [for subnet in data.aws_subnet.my_database_subnets : subnet.id if subnet.availability_zone == data.aws_db_instance.my_database.availability_zone][0]
    availability_zone      = data.aws_subnet.private_subnets_c.availability_zone
    # data.aws_db_instance.database_2022.availability_zone
  }

  tags = merge(
    local.tags,
    {
      Resource_Type = "RDS-MSSQLServer JDBC-Connection for Glue-Crawler",
    }
  )
}

resource "aws_glue_catalog_database" "rds_sqlserver_glue_catalog_db" {
  name = "rds_sqlserver_dms"
  # create_table_default_permission {
  #   permissions = ["SELECT"]

  #   principal {
  #     data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
  #   }
  # }
}

resource "aws_glue_crawler" "rds-sqlserver-db-glue-crawler" {
  name          = "rds-sqlserver-${aws_db_instance.database_2022.identifier}-tf"
  role          = aws_iam_role.dms-glue-crawler-role.arn
  database_name = aws_glue_catalog_database.rds_sqlserver_glue_catalog_db.name
  description   = "Crawler to fetch database names"
  #   table_prefix  = "your_table_prefix"

  jdbc_target {
    connection_name = aws_glue_connection.rds_sqlserver_db_glue_connection.name
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

resource "aws_glue_trigger" "rds-sqlserver-db-crawler-glue_trigger" {
  name = "rds-sqlserver-db-crawler-trigger-tf"
  type = "ON_DEMAND"

  actions {
    crawler_name = aws_glue_crawler.rds-sqlserver-db-glue-crawler.name
  }
}
