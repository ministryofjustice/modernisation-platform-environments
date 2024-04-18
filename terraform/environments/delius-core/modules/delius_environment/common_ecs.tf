module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v4.0.2"

  name = "delius-core-${var.env_name}-cluster"

  tags = local.tags
}

resource "aws_security_group" "cluster" {
  name_prefix = "ecs-cluster-${var.env_name}"
  vpc_id      = var.account_config.shared_vpc_id
  lifecycle {
    create_before_destroy = true
  }
}
