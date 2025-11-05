resource "aws_dms_replication_instance" "dms_replication_instance" {
  #checkov:skip=CKV_AWS_222
  allocated_storage            = 30
  apply_immediately            = true
  auto_minor_version_upgrade   = false
  availability_zone            = "${data.aws_region.current.region}a"
  engine_version               = var.dms_config.engine_version
  kms_key_arn                  = var.account_config.kms_keys.general_shared
  multi_az                     = false
  preferred_maintenance_window = "wed:22:00-wed:23:30"
  publicly_accessible          = false
  replication_instance_class   = var.dms_config.replication_instance_class
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
  lifecycle {
    create_before_destroy = true
  }
}
