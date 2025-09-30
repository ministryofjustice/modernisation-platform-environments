#######################################
# RDS MySQL Instance for OIA
#######################################

resource "aws_db_subnet_group" "oia_db_subnets" {
  name       = "${local.application_name}-${local.environment}-db-subnet-group"
  subnet_ids = [
    data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_b.id,
    data.aws_subnet.private_subnets_c.id
  ]

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-db-subnet-group"
  })
}

resource "aws_db_instance" "oia_db" {
  identifier              = "${local.application_name}-${local.environment}-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = local.application_data.accounts[local.environment].db_instance_type
  allocated_storage       = local.application_data.accounts[local.environment].db_storage_gb
  max_allocated_storage   = 100
  storage_encrypted       = true
  deletion_protection     = local.application_data.accounts[local.environment].db_deletion_protection
  skip_final_snapshot     = true
  multi_az                = false
  publicly_accessible     = false

  db_name                 = "oia"
  username                = local.application_data.accounts[local.environment].spring_datasource_username
  password                = data.aws_secretsmanager_secret_version.oia_db_password.secret_string
  port                    = 3306

  vpc_security_group_ids  = [aws_security_group.oia_db.id]
  db_subnet_group_name    = aws_db_subnet_group.oia_db_subnets.name

  backup_retention_period = 7
  storage_type            = "gp3"

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-db"
  })
}
