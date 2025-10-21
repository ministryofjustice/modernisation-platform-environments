# # Security Group for WEBGATE LB
# resource "aws_security_group" "sg_webgate_lb" {
#   name        = "sg_webgate_lb"
#   description = "Inbound traffic control for WebGate loadbalancer"
#   vpc_id      = data.aws_vpc.shared.id

#   tags = merge(local.tags,
#     { Name = lower(format("sg-%s-%s-webgate-loadbalancer", local.application_name, local.environment)) }
#   )
# }


# # INGRESS Rules

# ### HTTPS

# resource "aws_security_group_rule" "ingress_traffic_webgatelb_443" {
#   security_group_id = aws_security_group.sg_webgate_lb.id
#   type              = "ingress"
#   description       = "HTTPS"
#   protocol          = "TCP"
#   from_port         = 443
#   to_port           = 443
#   cidr_blocks       = ["0.0.0.0/0"]
# }


# # EGRESS Rules

# ### All

# resource "aws_security_group_rule" "egress_traffic_webgatelb_80" {
#   security_group_id = aws_security_group.sg_webgate_lb.id
#   type              = "egress"
#   description       = "All"
#   protocol          = "TCP"
#   from_port         = 0
#   to_port           = 0
#   cidr_blocks       = ["0.0.0.0/0"]
# }





