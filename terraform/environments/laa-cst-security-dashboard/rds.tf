resource "random_password" "cst_db" {
  length  = 32
  special = false
}

data "aws_db_subnet_group" "cst_database" {
  name = "${local.application_name}-${local.environment}"
}

resource "aws_db_instance" "postgres_latest" {
  identifier              = "cst-postgres-db"
  allocated_storage       = 20
  db_subnet_group_name    = aws_db_subnet_group.default.name
  instance_class          = "db.t3.micro"
  engine                  = "postgres"
  engine_version          = "16"
  username                = "postgresadmin"
  password                = random_password.cst_db.result
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = true
  backup_retention_period = 1
  vpc_security_group_ids  = [aws_security_group.cst_ecs_sc.id]
  apply_immediately       = true

  tags = {
    Name = "PostgresLatest"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.postgres_latest.endpoint
}

output "rds_master_username" {
  value = aws_db_instance.postgres_latest.username
}

output "rds_master_password" {
  value = random_password.cst_db.result
  sensitive = true
}