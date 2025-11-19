resource "random_password" "cst_db" {
  length  = 32
  special = false
}

resource "aws_security_group" "cst_rds_sc" {
  name        = "ecs security group"
  description = "control access to the rds"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_db_instance" "cst_db" {
  identifier              = "cst-postgres-db"
  allocated_storage       = 20
  instance_class          = "db.t3.micro"
  engine                  = "postgres"
  engine_version          = "16"
  username                = "postgresadmin"
  password                = random_password.cst_db.result
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = true
  backup_retention_period = 1
  vpc_security_group_ids  = [aws_security_group.cst_rds_sc.vpc_id]
  apply_immediately       = true

  tags = {
    Name = "PostgresLatest"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.cst_db.endpoint
}

output "rds_master_username" {
  value = aws_db_instance.cst_db.username
}

output "rds_master_password" {
  value = random_password.cst_db.result
  sensitive = true
}