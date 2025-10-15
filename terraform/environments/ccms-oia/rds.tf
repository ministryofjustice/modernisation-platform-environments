#######################################
# RDS MySQL Instance for OPAHUB
#######################################

resource "aws_db_subnet_group" "opahub_db_subnets" {
  name = "${local.opa_app_name}-db-subnet-group"
  subnet_ids = [
    data.aws_subnet.data_subnets_a.id,
    data.aws_subnet.data_subnets_b.id,
    data.aws_subnet.data_subnets_c.id
  ]

  tags = merge(local.tags, {
    Name = "${local.opa_app_name}-db-subnet-group"
  })
}

resource "aws_db_instance" "opahub_db" {
  identifier          = "${local.opa_app_name}-db"
  engine              = "mysql"
  engine_version      = "8.0.40"
  instance_class      = local.application_data.accounts[local.environment].db_instance_type
  allocated_storage   = local.application_data.accounts[local.environment].db_storage_gb
  storage_type        = "gp3"
  storage_encrypted   = true
  deletion_protection = false
  multi_az            = true
  username            = jsondecode(data.aws_secretsmanager_secret_version.opahub_secrets.secret_string)["db_user"]
  password            = jsondecode(data.aws_secretsmanager_secret_version.opahub_secrets.secret_string)["db_password"]
  port                = 3306

  vpc_security_group_ids  = [aws_security_group.opahub_db.id]
  db_subnet_group_name    = aws_db_subnet_group.opahub_db_subnets.id
  option_group_name       = "default:mysql-8-0"
  backup_retention_period = 30
  #  snapshot_identifier     = local.application_data.accounts[local.environment].db_snapshot_identifier
  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  tags = merge(local.tags, {
    Name = "${local.opa_app_name}-db"
  })
  # lifecycle {
  #   ignore_changes = [
  #     username
  #   ]
  # }
}
