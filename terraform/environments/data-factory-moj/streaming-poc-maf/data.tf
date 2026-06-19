# ---------------------------------------------------------------------------------------------------------------------
# DATA Sources
# ---------------------------------------------------------------------------------------------------------------------
data "external" "msk_arn" {
  program = ["sh", "scripts/msk_arn.sh"]
  query = {
    cluster_name = "streaming-pov-msk"
  }
}

data "aws_msk_bootstrap_brokers" "msk" {
  cluster_arn = data.external.msk_arn.result.arn
}

data "aws_opensearch_domain" "opensearch" {
  domain_name = "streaming-pov-opensearch"
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.region}.s3"
}

