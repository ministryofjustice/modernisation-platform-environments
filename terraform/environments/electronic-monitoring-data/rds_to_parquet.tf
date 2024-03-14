locals {
    aws_db_instance
}

resource "aws_glue_crawler" "rds_to_parquet" {
    database_name = aws_db_instance.database_2022.address
    name = "rds_to_parquet"
    role = aws_iam_role.rds_to_parquet_role

    jdbc_target {
    connection_name = aws_glue_connection.rds_to_parquet.name
    path            = "database-v2022/%"
  }
}

resource "aws_glue_connection" "rds_to_parquet" {
    connection_properties = {
        JDBC_CONNECTION_URL = "jdbc:sqlserver:// ${aws_db_instance.database_2022.address}:${aws_db_instance.database_2022.address};database=${aws_dv_instance.database_2022.db_name}"
        PASSWORD = aws_secretsmanager_secret.db_password.value
        USERNAME = "admin"
    }
    name = "rds_to_parquet"
    physical_connection_requirements {
    security_group_id_list = [aws_security_group.db.id]
    subnet_id              = aws_db_subnet_group.db.subnet_ids
  }
}
