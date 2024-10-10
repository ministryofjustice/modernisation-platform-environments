resource "aws_datasync_agent" "main" {
  name       = "${local.application_name}-${local.environment}-datasync"
  ip_address = data.dns_a_record_set.datasync_activation_nlb.addrs[0]

  subnet_arns     = module.connected_vpc.private_subnet_arns
  vpc_endpoint_id = module.connected_vpc_endpoints.endpoints["datasync"].id

  tags = local.tags

  depends_on = [
    module.datasync_instance,
    module.datasync_activation_nlb_security_group
  ]
}
