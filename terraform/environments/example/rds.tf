# Example code to build an RDS database - based on mysql but could be :
# Amazon Aurora, PostgreSQL, MariaDB, Oracle, MicroSoft SQL Server. These will require the correct version
# The local.app_variables is picked from local but set up in application_variables.json
# Set these up in there and make sure the local points to that location

resource "aws_db_instance" "Example-RDS" {
  engine                      = "mysql"
  engine_version              = "5.7"
  instance_class              = local.app_variables.accounts[local.environment].db_instance_class
  db_name                     = "${local.application_name}${local.environment}database"
  identifier                  = "${local.application_name}-${local.environment}-database" 
  username                    = local.app_variables.accounts[local.environment].db_user
  password                    = aws_secretsmanager_secret_version.db_password.secret_string
  parameter_group_name        = "default.mysql5.7"
  skip_final_snapshot         = local.app_variables.accounts[local.environment].skip_final_snapshot
  allocated_storage           = local.app_variables.accounts[local.environment].db_allocated_storage
  max_allocated_storage       = local.app_variables.accounts[local.environment].db_max_allocated_storage
  maintenance_window          = local.app_variables.accounts[local.environment].maintenance_window
  allow_major_version_upgrade = local.app_variables.accounts[local.environment].allow_major_version_upgrade
  backup_window               = local.app_variables.accounts[local.environment].backup_window
  backup_retention_period     = local.app_variables.accounts[local.environment].retention_period
  tags = merge(local.tags,
    { Name = lower(format("%s-%s-example", local.application_name, local.environment)) }
  )
  }

#   resource "aws_db_instance_automated_backups_replication" "Example-RDS" {
#   source_db_instance_arn = local.app_variables.accounts[local.environment].source_database
#   retention_period       = 14
# }

# data "aws_db_snapshot" "snapshot" {
#   db_instance_identifier = aws_db_instance.Example-RDS.id
#   #source_db_instance_arn = local.app_variables.accounts[local.environment].db_snapshot_identifier
# }
