# Example code to build an RDS database - based on mysql but could be :
# Amazon Aurora, PostgreSQL, MariaDB, Oracle, MicroSoft SQL Server. These will require the correct version
# The local.app_variables is picked from local but set up in application_variables.json
# Set these up in there and make sure the local points to that location

resource "aws_db_instance" "Example-RDS" {
  engine                 = "mysql"
  engine_version        = "5.7"
  instance_class         = local.app_variables.accounts[local.environment].db_instance_class
  db_name               = "${local.application_name}${local.environment}database"
  identifier            = "${local.application_name}-${local.environment}-database" 
  username              = local.app_variables.accounts[local.environment].db_user
  password              = aws_secretsmanager_secret_version.db_password.secret_string
  parameter_group_name  = "default.mysql5.7"
  skip_final_snapshot   = true
  allocated_storage     = local.app_variables.accounts[local.environment].db_allocated_storage
  max_allocated_storage = local.app_variables.accounts[local.environment].db_max_allocated_storage
  maintenance_window    = "Sun:00:00-Sun:03:00"
  allow_major_version_upgrade = false
  }
