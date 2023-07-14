provider "aws" {
  region     = "eu-west-1"
  access_key = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["dms_source_account_access_key"]
  secret_key = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["dms_source_account_secret_key"]
  alias      = "mojdsd"
}

data "github_ip_ranges" "github_actions_ips" {}

