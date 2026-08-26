##############################################
### RDS MySQL — LinOTP 3.x Database
###
### Separate database from the EC2 MariaDB.
### LinOTP 3.x schema is incompatible with 2.x.
##############################################

resource "random_password" "linotp3_db_password" {
  length           = 32
  special          = false
  override_special = ""
}

resource "aws_secretsmanager_secret" "linotp3_db_password" {
  name                    = "${local.application_name}/${local.environment}/linotp3-db-password"
  description             = "RDS MySQL password for LinOTP 3.x ECS deployment"
  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/${local.environment}/linotp3-db-password" }
  )
}

resource "aws_secretsmanager_secret_version" "linotp3_db_password" {
  secret_id     = aws_secretsmanager_secret.linotp3_db_password.id
  secret_string = random_password.linotp3_db_password.result
}

resource "aws_db_subnet_group" "linotp3" {
  name       = "${local.application_name}-${local.environment}-linotp3"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-linotp3-db-subnet-group" }
  )
}

resource "aws_security_group" "rds_linotp3" {
  name_prefix = "lnw-${local.environment}-rds-linotp3-"
  description = "Allow MySQL access from LinOTP 3.x ECS tasks only"
  vpc_id      = aws_vpc.workspaces.id

  revoke_rules_on_delete = true

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-rds-linotp3" }
  )
}

resource "aws_security_group_rule" "rds_linotp3_ingress_ecs" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds_linotp3.id
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_linotp3.id
  description              = "MySQL from ECS LinOTP tasks"
}

resource "aws_security_group_rule" "rds_linotp3_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.rds_linotp3.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

resource "aws_db_instance" "linotp3" {
  identifier        = "${local.application_name}-${local.environment}-linotp3"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = "linotp3"
  username = "linotp"
  password = random_password.linotp3_db_password.result

  db_subnet_group_name   = aws_db_subnet_group.linotp3.name
  vpc_security_group_ids = [aws_security_group.rds_linotp3.id]

  multi_az                = false
  publicly_accessible     = false
  deletion_protection     = false
  skip_final_snapshot     = true
  backup_retention_period = 1

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-linotp3-db" }
  )

  depends_on = [aws_db_subnet_group.linotp3]
}
