# trivy:ignore:AVD-AWS-0080
resource "aws_db_instance" "wardship_db" {
  #checkov:skip=CKV_AWS_16: "Ensure all data stored in the RDS is securely encrypted at rest"
  #checkov:skip=CKV_AWS_118: "Ensure that enhanced monitoring is enabled for Amazon RDS instances" - false error
  #checkov:skip=CKV_AWS_157: "Ensure that RDS instances have Multi-AZ enabled"
  #checkov:skip=CKV_AWS_293: "Ensure that AWS database instances have deletion protection enabled"
  #checkov:skip=CKV_AWS_353: "Ensure that RDS instances have performance insights enabled"
  #checkov:skip=CKV_AWS_354: "Ensure RDS Performance Insights are encrypted using KMS CMKs"
  allocated_storage               = local.application_data.accounts[local.environment].allocated_storage
  db_name                         = local.application_data.accounts[local.environment].db_name
  storage_type                    = local.application_data.accounts[local.environment].storage_type
  engine                          = local.application_data.accounts[local.environment].engine
  identifier                      = local.application_data.accounts[local.environment].identifier
  engine_version                  = local.application_data.accounts[local.environment].engine_version
  instance_class                  = local.application_data.accounts[local.environment].instance_class
  username                        = local.application_data.accounts[local.environment].db_username
  password                        = random_password.password.result
  skip_final_snapshot             = true
  publicly_accessible             = local.is-development ? true : false
  vpc_security_group_ids          = [aws_security_group.postgresql_db_sc.id]
  db_subnet_group_name            = aws_db_subnet_group.dbsubnetgroup.name
  auto_minor_version_upgrade      = true
  allow_major_version_upgrade     = false
  ca_cert_identifier              = "rds-ca-rsa2048-g1"
  apply_immediately               = true
  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  maintenance_window              = local.is-production ? null : "tue:20:20-tue:20:50"
}

resource "aws_db_subnet_group" "dbsubnetgroup" {
  name       = "dbsubnetgroup"
  subnet_ids = data.aws_subnets.shared-public.ids
}

resource "aws_security_group" "postgresql_db_sc" {
  name        = "postgres_security_group"
  description = "control access to the database"
  vpc_id      = data.aws_vpc.shared.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_ingress_rule_1" {
  security_group_id            = aws_security_group.postgresql_db_sc.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allows ECS service to access RDS"
  referenced_security_group_id = aws_security_group.ecs_service.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_ingress_rule_2" {
  security_group_id            = aws_security_group.postgresql_db_sc.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow PSQL traffic from bastion"
  referenced_security_group_id = module.bastion_linux.bastion_security_group

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "rds_egress_rule_1" {
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  security_group_id = aws_security_group.postgresql_db_sc.id
  ip_protocol       = "-1"
  description       = "allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"

  lifecycle {
    create_before_destroy = true
  }
}
