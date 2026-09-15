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
  #checkov:skip=CKV2_AWS_64: To be used for test only. Will be removed after test.
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

