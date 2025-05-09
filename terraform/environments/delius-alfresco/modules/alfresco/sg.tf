resource "aws_security_group" "cluster" {
  name_prefix = "ecs-cluster-${var.env_name}"
  vpc_id      = var.account_config.shared_vpc_id
  lifecycle {
    create_before_destroy = true
  }
}