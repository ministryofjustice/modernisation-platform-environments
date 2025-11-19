resource "random_password" "cst_db" {
  length  = 32
  special = false
}

resource "aws_security_group" "cst_rds_sc" {
  name        = "ecs security group"
  description = "control access to the rds"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow access on HTTPS for the Global Protect VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["35.176.93.186/32"]
  }

  egress {
    description = "allow all outbound traffic for port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound traffic for port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "cst_db" {
  identifier              = "cst-postgres-db"
  allocated_storage       = 20
  db_subnet_group_name    = locals.db_subnet_group_name
  instance_class          = "db.t3.micro"
  engine                  = "postgres"
  engine_version          = "16"
  username                = "postgresadmin"
  password                = random_password.cst_db.result
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = true
  backup_retention_period = 1
  vpc_security_group_ids  = [aws_security_group.cst_rds_sc.id]
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