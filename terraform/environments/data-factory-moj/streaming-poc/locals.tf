# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  name              = "streaming-pov"
  ecs_prefix        = "${local.name}-ecs"
  sdg_prefix        = "${local.ecs_prefix}-sdg"
  alerts_prefix     = "${local.ecs_prefix}-alerts"
  capacity_provider = local.environment == "development" ? "FARGATE_SPOT" : null

  ecr_repositories = {
    sdg    = "${local.name}-sdg"
    alerts = "${local.name}-alerts"
  }

  extended_tags = merge(local.tags, {
    component = local.name
  })
}
