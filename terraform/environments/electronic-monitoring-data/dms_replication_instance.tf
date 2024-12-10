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
  # depends_on = [aws_iam_role_policy_attachment.dms-vpc-role-AmazonDMSVPCManagementRole]
  depends_on = [aws_iam_role.dms_vpc_role]
}

# ==========================================================================

# Create a new replication instance

resource "aws_dms_replication_instance" "dms_replication_instance" {
  allocated_storage          = var.dms_allocated_storage_gib
  apply_immediately          = true
  auto_minor_version_upgrade = true
  availability_zone          = var.dms_availability_zone
  engine_version             = var.dms_engine_version
  kms_key_arn                = aws_kms_key.dms_replication_instance_key.arn
  multi_az                   = false
  #   preferred_maintenance_window = "sun:10:30-sun:14:30"
  publicly_accessible         = false
  replication_instance_class  = var.dms_replication_instance_class
  replication_instance_id     = "dms-replication-instance-tf"
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
    aws_iam_role.dms_vpc_role,
    aws_iam_role.dms_cloudwatch_logs_role,
    aws_iam_role.dms_endpoint_role
  ]

}


resource "aws_kms_key" "dms_replication_instance_key" {
  description = "KMS key for DMS replication instance encryption"
  #checkov:skip=CKV_AWS_7
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "dms-key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow DMS use of the key",
      "Effect": "Allow",
      "Principal": {
        "Service": "dms.${data.aws_region.current.name}.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
