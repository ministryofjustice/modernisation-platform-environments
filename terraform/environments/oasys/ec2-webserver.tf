

# #------------------------------------------------------------------------------
# # Common Security Group for webserver Instances
# #------------------------------------------------------------------------------

# resource "aws_security_group" "webserver_common" {
#   #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource" - attached in nomis-stack module
#   description = "Common security group for webserver instances"
#   name        = "webserver-common"
#   vpc_id      = local.vpc_id

#   ingress {
#     description     = "SSH from Bastion"
#     from_port       = "22"
#     to_port         = "22"
#     protocol        = "TCP"
#     security_groups = [module.bastion_linux.bastion_security_group]
#   }

#   ingress {
#     description     = "access from Windows Jumpserver (admin console)"
#     from_port       = "7001"
#     to_port         = "7001"
#     protocol        = "TCP"
#     security_groups = [aws_security_group.jumpserver-windows.id]
#   }

#   ingress {
#     description     = "access from Windows Jumpserver"
#     from_port       = "8080"
#     to_port         = "8080"
#     protocol        = "TCP"
#     security_groups = [aws_security_group.jumpserver-windows.id]
#   }

#   ingress {
#     description = "access from Windows Jumpserver and loadbalancer (forms/reports)"
#     from_port   = "7777"
#     to_port     = "7777"
#     protocol    = "TCP"
#     security_groups = [
#       aws_security_group.jumpserver-windows.id,
#       aws_security_group.internal_elb.id
#     ]
#   }

#   ingress {
#     description = "access from Cloud Platform Prometheus server"
#     from_port   = "9100"
#     to_port     = "9100"
#     protocol    = "TCP"
#     cidr_blocks = [local.cidrs.cloud_platform]
#   }

#   ingress {
#     description = "access from Cloud Platform Prometheus script exporter collector"
#     from_port   = "9172"
#     to_port     = "9172"
#     protocol    = "TCP"
#     cidr_blocks = [local.cidrs.cloud_platform]
#   }

#   egress {
#     description = "allow all"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     #tfsec:ignore:aws-vpc-no-public-egress-sgr
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(
#     local.tags,
#     {
#       Name = "webserver-commmon"
#     }
#   )
# }







