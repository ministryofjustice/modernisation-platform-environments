################################################################################
# PowerBI Gateway - Locals
################################################################################

locals {
  # Get current environment configuration based on workspace
  environment_configuration     = local.environment_configurations[local.environment]
  powerbi_gateway_instance_name = "${local.environment}-powerbi"
  powerbi_gateway_role          = "${local.environment}-powerbi-role"
}
