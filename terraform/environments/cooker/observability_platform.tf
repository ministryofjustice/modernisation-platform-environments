# Observability Platform tenant, to test Grafana Cloud and PDC against the development stack.
# The PDC agent's token secret is created in observability-platform-development, so apply that first.
module "observability_platform_tenant" {
  # Only the development workspace exists for this account
  count = local.is-development ? 1 : 0

  source = "github.com/ministryofjustice/terraform-aws-observability-platform-tenant?ref=03f883d6c4994539447243e3186f41e3922ab482" # v3.1.0

  observability_platform_account_id = local.environment_management.account_ids["observability-platform-development"]

  grafana_cloud = {
    stack = "development"
    pdc_agent = {
      # Opt in, matching pdc_enabled in Observability Platform's Grafana Cloud tenant configuration
      enabled = true
      # The test HTTPS server in network-test-infra.tf. Its subnet's CIDR is known at plan time, unlike its private IP
      allowed_targets = [
        { cidr_block = data.aws_subnet.private_subnets_a.cidr_block, port = 443 },
      ]
    }
  }

  tags = local.tags
}
