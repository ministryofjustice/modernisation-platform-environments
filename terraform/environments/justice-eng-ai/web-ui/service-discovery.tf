# Private service discovery so Builder can reach Forge directly within the
# VPC (same-origin proxy, see MPAPB_FORGE_UPSTREAM_URL in ecs.tf and
# local.forge_upstream_url in forge-journey-lab.tf) without going through
# the public ALB. Only created once single-url mode is actually in use.
resource "aws_service_discovery_private_dns_namespace" "internal" {
  count = local.forge_single_url_enabled ? 1 : 0

  name        = "${local.application_name}.internal"
  description = "Private DNS for same-VPC service-to-service traffic"
  vpc         = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_service_discovery_service" "forge" {
  count = local.forge_single_url_enabled ? 1 : 0

  name = local.forge_name

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {}

  tags = local.tags
}
