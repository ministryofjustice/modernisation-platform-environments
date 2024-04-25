resource "aws_dms_replication_instance" "test" {
  allocated_storage            = 30
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  availability_zone            = data.aws_region.current.name
  engine_version               = "3.5"
  kms_key_arn                  = var.account_config.kms_keys.general_shared
  multi_az                     = false
  preferred_maintenance_window = "wed:22:00-wed:23:30"
  publicly_accessible          = false
  replication_instance_class   = var.instance_class
  replication_instance_id      = "${var.env_name}-dms-instance"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.this.id
  network_type                 = "IPV4"

  tags = var.tags

  vpc_security_group_ids = [
    aws_security_group.dms.id
  ]


}
resource "aws_dms_replication_subnet_group" "this" {
  replication_subnet_group_description = "subnet for dms replication"
  replication_subnet_group_id          = "${var.env_name}-dms-subnet-group"
  subnet_ids                           = var.account_config.ordered_private_subnet_ids
}
