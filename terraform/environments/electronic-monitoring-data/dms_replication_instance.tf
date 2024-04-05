# Create a new replication subnet group
resource "aws_dms_replication_subnet_group" "dms_replication_subnet_group" {
  replication_subnet_group_description = "RDS subnet group"
  replication_subnet_group_id          = "rds-replication-subnet-group-tf"

  subnet_ids = tolist(aws_db_subnet_group.db.subnet_ids)

  tags = merge(
    local.tags,
    {
      Resource_Type = "DMS Replication Subnet Group",
    }
  )

  # explicit depends_on is needed since this resource doesn't reference the role or policy attachment
  depends_on = [aws_iam_role_policy_attachment.dms-vpc-role-AmazonDMSVPCManagementRole]
}

# ==========================================================================

# Create a new replication instance
resource "aws_dms_replication_instance" "t3micro_dms_replication_instance" {
  allocated_storage          = 20
  apply_immediately          = true
  auto_minor_version_upgrade = true
  availability_zone          = "eu-west-2b"
  #   engine_version               = "3.5.1"
  #   kms_key_arn                  = "arn:aws:kms:eu-west-2:800964199911:key/b7f54acb-16a3-4958-9340-3bdf5f5842d8"
  multi_az = false
  #   preferred_maintenance_window = "sun:10:30-sun:14:30"
  publicly_accessible         = false
  replication_instance_class  = "dms.t3.micro"
  replication_instance_id     = "t3micro-dms-replication-instance-tf"
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms_replication_subnet_group.id

  tags = merge(
    local.tags,
    {
      Resource_Type = "DMS Replication Instance",
    }
  )

  vpc_security_group_ids = [
    aws_security_group.dms_ri_security_group.id,
  ]

  depends_on = [
    aws_iam_role_policy_attachment.dms-endpoint-role,
    aws_iam_role_policy_attachment.dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole,
    aws_iam_role_policy_attachment.dms-vpc-role-AmazonDMSVPCManagementRole
  ]
}
