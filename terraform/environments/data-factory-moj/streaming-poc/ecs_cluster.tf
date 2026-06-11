# ---------------------------------------------------------------------------------------------------------------------
# ECS Cluster
# ---------------------------------------------------------------------------------------------------------------------
module "ecs_cluster" {
  count = contains(["development"], local.environment) ? 1 : 0
  
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v6.0.2"
  name   = "${local.ecs_prefix}-cluster"
  
  tags = local.tags
}
