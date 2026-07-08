# =============================================================================
# Access Test Postgres - Test only
#
# Restores the "Access" operational test database into a throwaway RDS instance
# in the test account (766696030771), placed in the shared VPC data subnets.
#
# Source: a shared, encrypted snapshot in the ADS/LAA Data Factory account
# (754256621582), snapshot "ads-staging-db-new-key" (PostgreSQL 17.5).
#
# KMS approach (Option B):
#   The source snapshot is encrypted under a KMS key we do not own. Rather than
#   run the restored DB under that external key indefinitely, we copy the
#   snapshot locally (aws_db_snapshot_copy) re-encrypting it with a DF-owned
#   CMK, then restore from the copy. This decouples the DB from the source
#   account key so revocation there cannot break our instance.
# =============================================================================

locals {
  access_source_snapshot_arn = "arn:aws:rds:eu-west-2:754256621582:snapshot:ads-staging-db-new-key"
}

# ---------------------------------------------------------------------------
# DF-owned CMK for the restored Access RDS
# ---------------------------------------------------------------------------
resource "aws_kms_key" "access_rds" {
  count = local.is-test ? 1 : 0

  description         = "KMS key for the restored Access test Postgres RDS"
  enable_key_rotation = true

  tags = local.tags
}

resource "aws_kms_alias" "access_rds" {
  count = local.is-test ? 1 : 0

  name          = "alias/${local.application_name}-access-rds"
  target_key_id = aws_kms_key.access_rds[0].key_id
}

# ---------------------------------------------------------------------------
# Local re-encrypted copy of the shared snapshot
# ---------------------------------------------------------------------------
resource "aws_db_snapshot_copy" "access" {
  count = local.is-test ? 1 : 0

  source_db_snapshot_identifier = local.access_source_snapshot_arn
  target_db_snapshot_identifier = "${local.application_name}-access-staging-copy"
  kms_key_id                    = aws_kms_key.access_rds[0].arn

  # copy_tags is not permitted for shared/public source snapshots; we apply our
  # own tags below instead.
  tags = local.tags
}

# ---------------------------------------------------------------------------
# Networking - data subnet tier of the shared VPC
# ---------------------------------------------------------------------------
resource "aws_db_subnet_group" "access" {
  count = local.is-test ? 1 : 0

  name       = "${local.application_name}-access"
  subnet_ids = data.aws_subnets.shared-data.ids

  tags = local.tags
}

#checkov:skip=CKV2_AWS_5:Security group is attached to the aws_db_instance below
resource "aws_security_group" "access_rds" {
  count = local.is-test ? 1 : 0

  name        = "${local.application_name}-access-rds"
  description = "Access test Postgres RDS - allow PostgreSQL from within the shared VPC"
  vpc_id      = data.aws_vpc.shared.id

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "access_rds_postgres" {
  count = local.is-test ? 1 : 0

  security_group_id = aws_security_group.access_rds[0].id
  description       = "PostgreSQL from within the shared VPC"
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "access_rds_all" {
  count = local.is-test ? 1 : 0

  security_group_id = aws_security_group.access_rds[0].id
  description       = "Allow all outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---------------------------------------------------------------------------
# Parameter group - enable logical replication for downstream DMS CDC
# ---------------------------------------------------------------------------
resource "aws_db_parameter_group" "access" {
  count = local.is-test ? 1 : 0

  name   = "${local.application_name}-access-postgres17"
  family = "postgres17"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Restored DB instance (throwaway test copy)
# ---------------------------------------------------------------------------
#trivy:ignore:AVD-AWS-0133 Enhanced monitoring not required for throwaway test DB
#trivy:ignore:AVD-AWS-0177 IAM auth not required for throwaway test DB
#checkov:skip=CKV_AWS_118:Enhanced monitoring not required for throwaway test DB
#checkov:skip=CKV_AWS_129:Log exports not required for throwaway test DB
#checkov:skip=CKV_AWS_157:Multi-AZ not required for throwaway test DB
#checkov:skip=CKV_AWS_161:IAM database authentication not required for throwaway test DB
#checkov:skip=CKV_AWS_293:Deletion protection intentionally disabled for throwaway test DB
#checkov:skip=CKV_AWS_353:Performance Insights not required for throwaway test DB
#checkov:skip=CKV_AWS_354:Performance Insights encryption not required for throwaway test DB
#checkov:skip=CKV2_AWS_30:Query logging not required for throwaway test DB
#checkov:skip=CKV2_AWS_60:Copy tags to snapshot not required for throwaway test DB
resource "aws_db_instance" "access" {
  count = local.is-test ? 1 : 0

  identifier          = "${local.application_name}-access"
  snapshot_identifier = aws_db_snapshot_copy.access[0].db_snapshot_arn

  engine         = "postgres"
  engine_version = "17.5"
  instance_class = "db.t3.medium"

  db_subnet_group_name   = aws_db_subnet_group.access[0].name
  vpc_security_group_ids = [aws_security_group.access_rds[0].id]
  parameter_group_name   = aws_db_parameter_group.access[0].name

  kms_key_id        = aws_kms_key.access_rds[0].arn
  storage_encrypted = true

  multi_az            = false
  publicly_accessible = false

  apply_immediately   = true
  deletion_protection = false
  skip_final_snapshot = true

  tags = local.tags

  lifecycle {
    # Master credentials, engine version and the source snapshot are inherited
    # from the restored snapshot; avoid perpetual diffs / accidental replacement.
    ignore_changes = [snapshot_identifier, engine_version]
  }
}
