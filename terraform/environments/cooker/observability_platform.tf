# Observability Platform tenant, pre-release, to test Grafana Cloud and PDC against the development stack.
# The PDC agent's token secret is created in observability-platform-development, so apply that first.
module "observability_platform_tenant" {
  # Only the development workspace exists for this account
  count = local.is-development ? 1 : 0

  # Draft ministryofjustice/terraform-aws-observability-platform-tenant#126
  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=bb733ea58ebd2157ee02216142e37427d221d02e"

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-development"]

  grafana_cloud = {
    stack = "development"
    pdc_agent = {
      # The test HTTPS server in network-test-infra.tf. Its subnet's CIDR is known at plan time, unlike its private IP
      allowed_targets = [
        { cidr_block = data.aws_subnet.private_subnets_a.cidr_block, port = 443 },
      ]
    }
  }

  tags = local.tags
}
