resource "aws_secretsmanager_secret" "db_glue_connection" {
  name = "db_glue_connection"
}

resource "aws_secretsmanager_secret_version" "db_glue_connection" {
  secret_id = aws_secretsmanager_secret.db_glue_connection.id
  secret_string = jsonencode(
    {
      "host"     = "${aws_db_instance.database_2022.address},${aws_db_instance.database_2022.port}",
      "username" = aws_db_instance.database_2022.username,
      "password" = aws_secretsmanager_secret_version.db_password.secret_string,
      "engine"   = "sqlserver",
      "port"     = aws_db_instance.database_2022.port
    }
  )
}