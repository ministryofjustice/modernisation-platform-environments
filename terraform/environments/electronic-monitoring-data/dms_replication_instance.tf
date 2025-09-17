# Create a new replication subnet group
resource "aws_dms_replication_subnet_group" "dms_replication_subnet_group" {
  count                                = local.is-production || local.is-development ? 1 : 0
  replication_subnet_group_description = "RDS subnet group"
  replication_subnet_group_id          = "rds-replication-subnet-group-tf"

  subnet_ids = tolist(aws_db_subnet_group.db[0].subnet_ids)

  tags = merge(
    local.tags,
    {
      Resource_Type = "DMS Replication Subnet Group",
    }
  )

  # explicit depends_on is needed since this resource doesn't reference the role or policy attachment
  # depends_on = [aws_iam_role_policy_attachment.dms-vpc-role-AmazonDMSVPCManagementRole]
  depends_on = [aws_iam_role.dms_vpc_role]
}

# ==========================================================================

# Create a new replication instance

resource "aws_dms_replication_instance" "dms_replication_instance" {
  count = local.is-production || local.is-development ? 1 : 0
  #checkov:skip=CKV_AWS_212
  allocated_storage          = var.dms_allocated_storage_gib
  apply_immediately          = true
  auto_minor_version_upgrade = true
  availability_zone          = var.dms_availability_zone
  engine_version             = var.dms_engine_version
  # kms_key_arn                = aws_kms_key.dms_replication_instance_key.arn
  multi_az = false
  #   preferred_maintenance_window = "sun:10:30-sun:14:30"
  publicly_accessible         = false
  replication_instance_class  = var.dms_replication_instance_class
  replication_instance_id     = "dms-replication-instance-tf"
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms_replication_subnet_group[0].id

  tags = merge(
    local.tags,
    {
      Resource_Type = "DMS Replication Instance",
    }
  )

  vpc_security_group_ids = [
    aws_security_group.dms_ri_security_group[0].id,
  ]

  depends_on = [
    aws_iam_role.dms_vpc_role,
    aws_iam_role.dms_cloudwatch_logs_role,
    aws_iam_role.dms_endpoint_role
  ]

}

