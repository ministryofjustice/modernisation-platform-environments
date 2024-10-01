# resource "aws_datasync_agent" "main" {
#   name       = "${local.application_name}-${local.environment}-datasync"
#   ip_address = module.datasync_instance.private_ip

#   tags = local.tags

#   depends_on = [module.datasync_instance]
# }
