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

  # health_check_custom_config is force-new: the deployed service was created
  # without it, so adding it here would replace the service, re-triggering
  # the ECS deregistration race below on every apply. Left unset to match
  # deployed state.

  tags = local.tags
}

# AWS's deregistration of the ECS task's Cloud Map instance (triggered when
# aws_ecs_service.forge is updated/destroyed) isn't immediately visible to
# the ServiceDiscovery API, so deleting the service straight after can fail
# with "ResourceInUse: Service contains registered instances". Depending on
# the service here and delaying this resource's own destruction pushes
# *its* removal until after the ECS service's -- which, because Terraform
# destroys in reverse-dependency order, is exactly the gap that needs the wait.
resource "time_sleep" "forge_service_discovery_deregistration" {
  count = local.forge_single_url_enabled ? 1 : 0

  depends_on       = [aws_service_discovery_service.forge]
  destroy_duration = "60s"
}

