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

data "aws_opensearch_domain" "opensearch" {
  for_each    = toset(contains(local.deploy_to, local.environment) ? ["opensearch"] : [])
  domain_name = "streaming-pov-opensearch"
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.region}.s3"
}

