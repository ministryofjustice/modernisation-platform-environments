provider "aws" {
  alias      = "mojdsd"
}

data "github_ip_ranges" "github_actions_ips" {}

