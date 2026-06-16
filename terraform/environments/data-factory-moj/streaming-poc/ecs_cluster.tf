# ---------------------------------------------------------------------------------------------------------------------
# ECS Cluster
# ---------------------------------------------------------------------------------------------------------------------
module "ecs_cluster" {
  count = contains(local.deploy_to, local.environment) ? 1 : 0

  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=697b010957fabc36b7f648bc535021231f748674" # v6.0.2
  name   = "${local.ecs_prefix}-cluster"

  tags = local.extended_tags
}

resource "aws_security_group" "cluster" {
  count = contains(local.deploy_to, local.environment) ? 1 : 0

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
