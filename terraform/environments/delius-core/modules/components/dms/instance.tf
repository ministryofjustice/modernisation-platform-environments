resource "aws_dms_replication_instance" "test" {
  allocated_storage            = 20
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  availability_zone            = data.aws_region.current.name
  engine_version               = "3.1.4"
  kms_key_arn                  = var.account_config.kms_keys.general_shared
  multi_az                     = false
  preferred_maintenance_window = "wed:22:00-wed:23:30"
  publicly_accessible          = true
  replication_instance_class   = var.instance_class
  replication_instance_id      = "${var.env_name}-dms-instance"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.test-dms-replication-subnet-group-tf.id

  tags = var.tags

  vpc_security_group_ids = [
    aws_security_group.dms.id
  ]

  depends_on = [
    aws_iam_role_policy_attachment.dms-access-for-endpoint-AmazonDMSRedshiftS3Role,
    aws_iam_role_policy_attachment.dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole,
    aws_iam_role_policy_attachment.dms-vpc-role-AmazonDMSVPCManagementRole
  ]
}
