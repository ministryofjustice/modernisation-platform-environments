# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  name              = "streaming-pov"
  ecs_prefix        = "${local.name}-ecs"
  sdg_prefix        = "${local.ecs_prefix}-sdg"
  alerts_prefix     = "${local.ecs_prefix}-alerts"
  deploy_to         = ["development"]
  capacity_provider = contains(["development"], local.environment) ? "FARGATE_SPOT" : null
  msk_bootstrap_brokers = contains(local.deploy_to, local.environment) ? (
    try(data.aws_msk_bootstrap_brokers.msk["msk"].bootstrap_brokers_sasl_iam, null)
  ) : null
  msk_cluster_arn = contains(local.deploy_to, local.environment) ? (
    try(data.external.msk_arn["msk"].result.arn, null)
  ) : null
  msk_group_arns = contains(local.deploy_to, local.environment) ? [
    format("%s/*", replace(try(data.external.msk_arn["msk"].result.arn, null), ":cluster/", ":group/"))
  ] : null
  msk_topic_arns = contains(local.deploy_to, local.environment) ? [
    format("%s/*", replace(try(data.external.msk_arn["msk"].result.arn, null), ":cluster/", ":topic/"))
  ] : null

  ecr_repositories = {
    sdg    = "${local.name}-sdg"
    alerts = "${local.name}-alerts"
  }

  extended_tags = merge(local.tags, {
    component = local.name
  })
}
