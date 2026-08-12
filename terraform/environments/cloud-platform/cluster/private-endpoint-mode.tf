###############################################################################
# Publishes private_endpoint_mode to SSM so the network component can gate the
# SSM relay on the same flag that sets endpoint_public_access here (#8425).
#
# Apply `cluster` before `network` in BOTH directions. On disable, the public
# endpoint must be restored before the relay is destroyed, or the cluster
# becomes unreachable.
#
# Keyed on cp_vpc_name (network is per-VPC), so assumes one cluster per VPC.
###############################################################################

resource "aws_ssm_parameter" "private_endpoint_mode" {
  name        = "/cloud-platform/${local.cp_vpc_name}/private-endpoint-mode"
  description = "Whether this cluster uses a private-only EKS API endpoint (#8425)"
  type        = "String"
  value       = tostring(local.environment_configuration.private_endpoint_mode)

  tags = local.tags
}
