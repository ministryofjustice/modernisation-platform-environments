locals {
  /*  To debug these, you need to:
      1. cd terraform/environments/data-platform/network
      2. aws-sso login
      3. aws-sso exec --profile data-platform-${STAGE:-"development"}:platform-engineer-admin
      4. terraform init
      5. terraform workspace select ${AWS_SSO_PROFILE%%:*}
      6. terraform console
      7. Type the local you want to debug, e.g. local.subnets

      If you make changes, you need to exit the console and re-run from step 6
  */

  /* Configurations */
  environment_configuration = local.environment_configurations[local.environment]
  network_configuration     = yamldecode(file("${path.module}/configuration/network.yml"))["environment"][local.environment]

  /* CloudWatch Log Groups
    - These are stored as locals so we can reference them in their KMS key modules
  */
  vpc_flow_logs_log_group_name           = "/aws/vpc/${local.application_name}-${local.environment}-flow"
  network_firewall_flow_log_group_name   = "/aws/network-firewall/${local.application_name}-${local.environment}-flow"
  network_firewall_alerts_log_group_name = "/aws/network-firewall/${local.application_name}-${local.environment}-alerts"
  route53_resolver_log_group_name        = "/aws/route53-resolver/${local.application_name}-${local.environment}"

  /* Subnets
    - Build a map of subnets from the network configuration excluding unallocated AZs
      which results in:
        {
          "data-aza" = {
            "az"         = "a"
            "cidr_block" = "10.199.128.0/25"
            "type"       = "data"
          }
        }
  */
  subnets = merge([
    for subnet_type, azs in local.network_configuration.vpc.subnets : {
      for az, cidr in azs :
      "${subnet_type}-${az}" => {
        cidr_block = cidr
        type       = subnet_type
        az         = trimprefix(az, "az")
      }
    }
  ]...)

  /* Additional CIDR Subnets
    - Similar to above but for any additional CIDR blocks defined in the VPC
      which results in:
        {
          "transit_gateway-attachments-a" = {
            "az"         = "a"
            block_name  = "transit-gateway"
            "cidr_block" = "192.168.255.0/28"
            "type"       = "attachments"
        }
  */
  additional_cidr_subnets = merge([
    for block_name, block_config in try(local.network_configuration.vpc.additional_cidr_blocks, {}) : merge([
      for subnet_type, azs in block_config.subnets : {
        for az, cidr in azs :
        "${block_name}-${subnet_type}-${az}" => {
          cidr_block = cidr
          type       = subnet_type
          az         = trimprefix(az, "az")
          block_name = replace(block_name, "_", "-")
        }
      }
    ]...)
  ]...)

  /* Network Firewall Rules */
  network_firewall_rules = {
    fqdn = yamldecode(file("${path.module}/configuration/network-firewall/rules/fqdn-rules.yml"))
    ip   = yamldecode(file("${path.module}/configuration/network-firewall/rules/ip-rules.yml"))
  }
}
