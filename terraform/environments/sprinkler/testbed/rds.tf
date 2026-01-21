# Random password for RDS
resource "random_password" "rds" {
  length  = 16
  special = true
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name        = "${local.application_name}-${local.component_name}-rds"
  description = "Security group for ${local.application_name} ${local.component_name} RDS instance"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.component_name}-rds"
    }
  )
}

# Allow PostgreSQL from EC2
resource "aws_vpc_security_group_ingress_rule" "rds_from_ec2" {
  security_group_id            = aws_security_group.rds.id
  description                  = "Allow PostgreSQL from EC2"
  cidr_ipv4                    = data.aws_subnet.private_subnets_a.cidr_block
  ip_protocol                  = "tcp"
  from_port                    = 54320
  to_port                      = 54320
}

# DB subnet group
resource "aws_db_subnet_group" "rds" {
  name       = "${local.application_name}-${local.component_name}"
  subnet_ids = data.aws_subnets.shared-data.ids

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.component_name}"
    }
  )
}

# PostgreSQL RDS instance
resource "aws_db_instance" "rds" {
  identifier             = "${local.application_name}-${local.component_name}"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "18.1"
  instance_class         = "db.t3.micro"
  db_name                = "testdb"
  username               = "postgres"
  password               = random_password.rds.result
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  storage_encrypted      = true

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.component_name}"
    }
  )
}
