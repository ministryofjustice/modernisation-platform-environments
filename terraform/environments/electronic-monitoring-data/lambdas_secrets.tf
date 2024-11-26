resource "aws_secretsmanager_secret" "db_glue_connection" {
  name = "db_glue_connection"
}

resource "aws_secretsmanager_secret_version" "db_glue_connection" {
  secret_id = aws_secretsmanager_secret.db_glue_connection.id
  secret_string = local.create_rds_instance == 1 ? jsonencode(
    {
      "host"     = "${aws_db_instance.database_2022[0].address},${aws_db_instance.database_2022[0].port}",
      "username" = aws_db_instance.database_2022[0].username,
      "password" = aws_secretsmanager_secret_version.db_password.secret_string,
      "engine"   = "sqlserver",
      "port"     = aws_db_instance.database_2022[0].port
    }
  ) : ""
}