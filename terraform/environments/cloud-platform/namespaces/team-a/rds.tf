###############################################################################
# US-005c: RDS Instance for team-a (Terraform approach)
#
# App team requests a database by adding this config to their namespace
# directory and running terraform apply.
#
# Prerequisites:
# - Shared DB subnet group "platform-db-subnet-group" (network/vpc.tf)
# - RDS service-linked role (account bootstrap)
# - Secrets Store CSI Driver addon (cluster-core/secrets-store-csi.tf)
###############################################################################

# --- Unique identifiers ------------------------------------------------------

resource "random_id" "rds" {
  byte_length = 8
}

resource "random_password" "rds" {
  length  = 16
  special = false
}

resource "random_string" "rds_username" {
  length  = 8
  special = false
}

# --- KMS encryption ----------------------------------------------------------

resource "aws_kms_key" "rds" {
  description = "cloud-platform-${random_id.rds.hex}-rds"
}

resource "aws_kms_alias" "rds" {
  name          = "alias/cloud-platform-${random_id.rds.hex}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# --- Security Group (per-database) -------------------------------------------
# Each database gets its own SG. Allows traffic from private + pod subnets
# on the database port only. Prevents cross-database access between teams.

resource "aws_security_group" "rds" {
  name        = "team-a-rds-${random_id.rds.hex}"
  description = "Allow Postgres from pod subnets and private subnets"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = concat(
      [for s in data.aws_subnet.private : s.cidr_block],
      [for s in data.aws_subnet.pod_private : s.cidr_block]
    )
    description = "Postgres from private + pod subnets"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Parameter Group ---------------------------------------------------------

resource "aws_db_parameter_group" "rds" {
  name   = "team-a-${random_id.rds.hex}"
  family = "postgres16"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "immediate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- RDS Instance ------------------------------------------------------------

resource "aws_db_instance" "this" {
  identifier     = "team-a-${random_id.rds.hex}"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_name  = "appdb"
  username = "cp${random_string.rds_username.result}"
  password = random_password.rds.result

  db_subnet_group_name   = "platform-db-subnet-group" # Shared — created in network/vpc.tf
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.rds.name
  ca_cert_identifier     = "rds-ca-rsa2048-g1"

  multi_az                = true
  publicly_accessible     = false # Required — SCP blocks public RDS instances
  deletion_protection     = false # PoC only — set true for production
  skip_final_snapshot     = true  # PoC only — set false for production
  backup_retention_period = 7
  copy_tags_to_snapshot   = true
  apply_immediately       = true

  tags = {
    Namespace = "team-a"
  }
}

# --- Secrets Manager ---------------------------------------------------------
# Stores credentials as JSON for the Secrets Store CSI Driver to mount.
# The secret path convention is: platform/<namespace>/<db-name>
# App teams reference this path in their SecretProviderClass YAML.

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "platform/team-a/orders-db"
  description = "RDS credentials for team-a orders-db (mounted via CSI Driver)"
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    host     = aws_db_instance.this.address
    port     = tostring(aws_db_instance.this.port)
    dbname   = aws_db_instance.this.db_name
    username = aws_db_instance.this.username
    password = random_password.rds.result
    endpoint = aws_db_instance.this.endpoint
  })
}
