# ---------------------------------------------------------------------------------------------------------------------
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  name              = "streaming-pov"
  ecs_prefix        = "${local.name}-ecs"
  sdg_prefix        = "${local.ecs_prefix}-sdg"
  alerts_prefix     = "${local.ecs_prefix}-alerts"
  kafka_ui_prefix   = "${local.ecs_prefix}-kafka-ui"
  deploy_to         = ["development"]
  capacity_provider = contains(local.deploy_to, local.environment) ? "FARGATE_SPOT" : null
  secretsmanager_kms_key_arn = contains(local.deploy_to, local.environment) ? (
    try(aws_kms_key.secretsmanager[0].arn, "*")
  ) : "*"
  secretsmanager_gitlab_token_arn = contains(local.deploy_to, local.environment) ? (
    try(aws_secretsmanager_secret.gitlab_token[0].arn, "*")
  ) : "*"
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
