data "aws_vpc" "cp3" {
  count = local.environment == "nonlive" ? 1 : 0

  tags = { Name = terraform.workspace }
}

data "aws_subnets" "cp3_private" {
  count = local.environment == "nonlive" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.cp3[0].id]
  }

  tags = { SubnetType = "Private" }
}

module "observability_platform_tenant" {
  count  = local.environment == "nonlive" ? 1 : 0
  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=03f883d6c4994539447243e3186f41e3922ab482" # v3.1.0

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-development"]
  grafana_cloud = {
    stack = "development"
    pdc_agent = {
      enabled    = true
      subnet_ids = sort(data.aws_subnets.cp3_private[0].ids)
      # Use the hub's private DNS names instead of the tenant module's per-VPC names.
      privatelink = false
      extra_args = [
        "-api-fqdn", "private-datasource-connect-api.eu-west-2.vpce.grafana.net",
        "-gateway-fqdn", "private-datasource-connect.eu-west-2.vpce.grafana.net",
      ]
    }
  }

  tags = local.tags
}
