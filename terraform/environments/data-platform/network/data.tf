data "aws_route53_resolver_query_log_config" "core_logging_s3" {
  filter {
    name   = "Name"
    values = ["core-logging-rlq-s3"]
  }
}

data "aws_vpc_endpoint" "network_firewall" {
  for_each = {
    for key, value in local.subnets : value.az => value
    if value.type == "firewall"
  }

  vpc_id = aws_vpc.main.id

  tags = {
    "AWSNetworkFirewallManaged" = "true"
    "Firewall"                  = aws_networkfirewall_firewall.main.arn
    "Name"                      = "${local.application_name}-${local.environment} (${data.aws_region.current.region}${each.key})"
  }
}

data "github_ip_ranges" "main" {}

data "aws_ec2_transit_gateway" "moj_tgw" {
  filter {
    name = "owner-id"
    values = ["037161842252"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
