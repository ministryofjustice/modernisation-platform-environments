# --------------------------------------------------------------------------------------------------------------------------------
# create_athena_external_tables
# --------------------------------------------------------------------------------------------------------------------------------

resource "aws_glue_job" "create_athena_external_tables" {
  name          = "create-athena-external-tables"
  role_arn      = aws_iam_role.create_athena_external_tables_glue.arn
  glue_version = "4.0"
  command {
    script_location = aws_s3_object.create_athena_external_tables.id
    python_version  = "3.9"

  }
  default_arguments = {
    "--job-language" = "python"
  }
}

# resource "aws_glue_connection" "example_connection" {
#   name = "create-athena-external-tables-connection"
#   connection_properties = {
#     "JDBC_CONNECTION_URL" = "jdbc:postgresql://example.com:5432/database"
#     "PASSWORD"            = "example"
#     "USERNAME"            = "example"
#   }
#   physical_connection_requirements {
#     availability_zone = "us-west-2a"
#     security_group_id_list = ["sg-12345678"]
#     subnet_id = "subnet-12345678"
#   }
# }