# 3. Glue Database and connections

#resource "aws_glue_catalog_database" "glue_database" {
#  name = var.database_name
#}
#
#resource "aws_glue_connection" "glue_connection" {
#  name = "${var.database_name}-connection"
#
#  connection_properties = {
#    "JDBC_CONNECTION_URL" = "jdbc:mysql://your-rds-endpoint:3306/${var.database_name}"
#    "USERNAME"            = "your-db-username"
#    "PASSWORD"            = "your-db-password"
#  }
#
#  physical_connection_requirements {
#    availability_zone    = "eu-west-2"
#    security_group_id_list = ["sg-xxxxxxx"]
#    subnet_id              = "subnet-xxxxxxx"
#  }
#}