resource "aws_security_group" "dms" {
  vpc_id      = var.account_info.vpc_id
  name        = "${var.env_name}-dms-sg"
  description = "Security group for DMS Replication Instances"
  lifecycle {
    create_before_destroy = true
  }
}
