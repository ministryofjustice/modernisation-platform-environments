provider "aws" {
  region = "eu-west-2"
  #   access_key = jsondecode(data.aws_secretsmanager_secret_version.get_tactical_products_rds_credentials.secret_string)["ACCESS_KEY"]
  #   secret_key = jsondecode(data.aws_secretsmanager_secret_version.get_tactical_products_rds_credentials.secret_string)["SECRET_KEY"]
  alias = "tacticalproducts"
}

data "github_ip_ranges" "github_actions_ips" {}
