# ---------------------------------------------------------------------------------------------------------------------
# ECS Cluster
# ---------------------------------------------------------------------------------------------------------------------
module "ecs_cluster" {
  count = contains(["development"], local.environment) ? 1 : 0

  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v6.0.2"
  name   = "${local.ecs_prefix}-cluster"

  tags = local.extended_tags
}

resource "aws_security_group" "cluster" {
  count = contains(["development"], local.environment) ? 1 : 0

  name_prefix = "${local.ecs_prefix}-cluster"
  vpc_id      = data.aws_vpc.shared.id
  description = "${local.ecs_prefix}-cluster SG"

  tags = merge(local.extended_tags, {
    Name = "${local.ecs_prefix}-cluster"
  })

  lifecycle {
    create_before_destroy = true
  }
}
