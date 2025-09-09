module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v6.0.0"

  name = "vcms-${local.environment}-cluster"

  tags = local.tags
}

resource "aws_security_group" "cluster" {
  name_prefix = "ecs-cluster-${local.environment}"
  vpc_id      = local.account_config.shared_vpc_id
  lifecycle {
    create_before_destroy = true
  }
}
