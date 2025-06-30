resource "aws_secretsmanager_secret" "password" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"

  name = "${var.name}-password"
}

resource "aws_secretsmanager_secret_version" "password" {
  depends_on = [aws_secretsmanager_secret.password]

  secret_id     = aws_secretsmanager_secret.password.id
  secret_string = random_password.password.result
}

data "aws_secretsmanager_secret" "password" {
  depends_on = [aws_secretsmanager_secret_version.password]

  name = "${var.name}-password"
}

data "aws_secretsmanager_secret_version" "password" {
  secret_id = data.aws_secretsmanager_secret.password.id
}

resource "aws_db_subnet_group" "subnets" {
  count      = var.enable_rds ? 1 : 0
  name       = "${var.name}-subnet"
  subnet_ids = var.subnets

  tags = merge(
    var.tags,
    {
      Resource_Type = "subnet"
      Name          = "${var.name}-subnet"
    }
  )
}

resource "aws_db_instance" "default" {
  #checkov:skip=CKV2_AWS_30:”Query Logging is not required"
  #checkov:skip=CKV2_AWS_60: “Ignore -Ensure RDS instance with copy tags to snapshots is enabled"
  #checkov:skip=CKV_AWS_129: "Ensure that respective logs of Amazon Relational Database Service (Amazon RDS) are enabled"
  #checkov:skip=CKV_AWS_161: "Ensure RDS database has IAM authentication enabled"
  #checkov:skip=CKV_AWS_354: "Ensure RDS Performance Insights are encrypted using KMS CMKs"
  #checkov:skip=CKV_AWS_157: "Ensure that RDS instances have Multi-AZ enabled"
  #checkov:skip=CKV_AWS_118: "Ensure that enhanced monitoring is enabled for Amazon RDS instances"
  #checkov:skip=CKV_AWS_353: "Ensure that RDS instances have performance insights enabled"
  #checkov:skip=CKV_AWS_226: "Ensure DB instance gets all minor upgrades automatically"
  #checkov:skip=CKV_AWS_293: "Ensure that AWS database instances have deletion protection enabled"

  count                   = var.enable_rds ? 1 : 0
  identifier              = var.name
  db_name                 = var.db_name
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = var.db_instance_class
  username                = var.master_user
  password                = data.aws_secretsmanager_secret_version.password.secret_string
  storage_type            = var.storage_type
  db_subnet_group_name    = aws_db_subnet_group.subnets[0].name
  maintenance_window      = var.maintenance_window
  backup_window           = var.backup_window
  backup_retention_period = var.back_up_period
  vpc_security_group_ids  = [aws_security_group.rds[0].id, aws_security_group.ec2_sec_group[0].id, ]
  skip_final_snapshot     = true
  kms_key_id              = var.kms
  storage_encrypted       = true
  apply_immediately       = true
  allocated_storage       = var.allocated_size
  max_allocated_storage   = var.max_allocated_size
  ca_cert_identifier      = var.ca_cert_identifier
  multi_az                = false
  tags = merge(
    var.tags,
    {
      Resource_Type = "rds"
      Name          = "${var.name}-rds"
    }
  )
}

resource "aws_db_instance" "replica" {
  count = (var.enable_rds && var.create_rds_replica) ? 1 : 0

  replicate_source_db     = aws_db_instance.default[0].identifier
  backup_retention_period = 7
  identifier              = "${var.name}-replica"
  instance_class          = var.db_instance_class
  vpc_security_group_ids  = [aws_security_group.rds[0].id, aws_security_group.ec2_sec_group[0].id, ]
  skip_final_snapshot     = true
  kms_key_id              = var.kms
  storage_encrypted       = true
  apply_immediately       = true
  max_allocated_storage   = var.max_allocated_size
  ca_cert_identifier      = var.ca_cert_identifier
  copy_tags_to_snapshot   = true
  multi_az                = false
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_!%^"
}
