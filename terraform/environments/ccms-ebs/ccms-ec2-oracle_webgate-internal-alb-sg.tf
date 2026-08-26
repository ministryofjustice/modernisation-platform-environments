# # Security Group for Webgate LB
# resource "aws_security_group" "sg_webgate_internal_alb" {
#   name        = "webgate_internal_alb"
#   description = "Inbound traffic control for Webgate Internal loadbalancer"
#   vpc_id      = data.aws_vpc.shared.id

#   tags = merge(local.tags,
#     { Name = lower(format("sg-webgate-loadbalancer-internal")) }
#   )
# }

# # INGRESS Rules

# ### HTTPS

# resource "aws_security_group_rule" "ingress_traffic_webgatealb_internal_443_workspaces" {
#   security_group_id = aws_security_group.sg_webgate_internal_alb.id
#   type              = "ingress"
#   description       = "HTTPS from LZ AWS Workspaces"
#   protocol          = "TCP"
#   from_port         = 443
#   to_port           = 443
#   cidr_blocks       = [local.application_data.accounts[local.environment].lz_aws_workspace_nonprod_prod]
# }

# resource "aws_security_group_rule" "ingress_traffic_webgatealb_internal_443_mojo_devices" {
#   security_group_id = aws_security_group.sg_webgate_internal_alb.id
#   type              = "ingress"
#   description       = "HTTPS from Mojo Devices"
#   protocol          = "TCP"
#   from_port         = 443
#   to_port           = 443
#   cidr_blocks       = [local.application_data.accounts[local.environment].mojo_devices]
# }

# # EGRESS Rules

# ### All

# resource "aws_security_group_rule" "egress_traffic_webgatealb_internal_all" {
#   security_group_id = aws_security_group.sg_ebsapps_internal_alb.id
#   type              = "egress"
#   description       = "All"
#   protocol          = "TCP"
#   from_port         = 0
#   to_port           = 0
#   cidr_blocks       = ["0.0.0.0/0"]
# }





