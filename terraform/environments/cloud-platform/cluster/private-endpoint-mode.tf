# Publishes private_endpoint_mode to SSM Parameter Store so the network component
# can gate the SSM relay on the same flag that controls the cluster endpoint.
# This is the single source of truth shared across the two components.
# Assumes one cluster per VPC; multiple clusters sharing a VPC would contend for
# this parameter (see ticket note).
resource "aws_ssm_parameter" "private_endpoint_mode" {
  name  = "/cloud-platform/${local.cp_vpc_name}/private-endpoint-mode"
  type  = "String"
  value = tostring(local.environment_configuration.private_endpoint_mode)
  tags  = local.tags
}
