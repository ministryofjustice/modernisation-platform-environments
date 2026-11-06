# ---------------------------------------------------------------------------------------------------------------------
# DATA Sources
# ---------------------------------------------------------------------------------------------------------------------
data "external" "msk_arn" {
  for_each = toset(contains(local.deploy_to, local.environment) ? ["msk"] : [])
  program  = ["sh", "scripts/msk_arn.sh"]
  query = {
    cluster_name = "streaming-pov-msk"
  }
}

data "aws_msk_bootstrap_brokers" "msk" {
  for_each    = toset(contains(local.deploy_to, local.environment) ? ["msk"] : [])
  cluster_arn = data.external.msk_arn["msk"].result.arn
}

data "aws_kms_key" "sns_topic_kmskey" {
  for_each = toset(contains(local.deploy_to, local.environment) ? ["sns"] : [])
  key_id   = "alias/streaming-poc-maf-sns"
}

data "aws_sns_topic" "drone_incursion_topic" {
  for_each = toset(contains(local.deploy_to, local.environment) ? ["topic"] : [])
  name     = "moj-pov-drone-incursion-alerts"
}
