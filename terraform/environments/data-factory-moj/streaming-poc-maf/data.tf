# ---------------------------------------------------------------------------------------------------------------------
# DATA Sources
# ---------------------------------------------------------------------------------------------------------------------
data "external" "msk_arn" {
  program = ["sh", "scripts/msk_arn.sh"]
  query = {
    cluster_name = "moj-msk"
  }
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.region}.s3"
}
