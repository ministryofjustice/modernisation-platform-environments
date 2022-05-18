# Example code to build an RDS database - based on mysql but could be :
# Amazon Aurora, PostgreSQL, MariaDB, Oracle, MicroSoft SQL Server. These will require the correct version

# resource "aws_db_instance" "Example-RDS" {
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = local.app_variables.accounts[local.environment].db_instance_class
#   db_name              = "${local.application_name}${local.environment}database"
#   username             = local.app_variables.accounts[local.environment].db_user
#   password             = aws_secretsmanager_secret_version.db_password.arn
#   #password             = "TestPassword123"
#   parameter_group_name = "default.mysql5.7"
#   skip_final_snapshot  = true
#   allocated_storage     = local.app_variables.accounts[local.environment].db_allocated_storage
#   max_allocated_storage = local.app_variables.accounts[local.environment].db_max_allocated_storage
# }

resource "random_password" "random_password" {

  length  = 32
  special = false
}
