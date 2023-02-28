# locals {
#   instance-userdata = <<EOF
# #!/bin/bash
# yum install -y httpd
# systemctl start httpd
# cat "0 8 * * * root systemctl start httpd" > /etc/cron.d/httpd_cron
# EOF
# }
# module "ec2_instance" {
#   source                 = "terraform-aws-modules/ec2-instance/aws"
#   version                = "~> 4.0"
#   name                   = "${local.environment}-landingzone-httptest"
#   ami                    = "ami-06672d07f62285d1d"
#   instance_type          = "t3a.small"
#   vpc_security_group_ids = [module.httptest_sg.security_group_id]
#   subnet_id              = local.application_data.accounts[local.environment].mp_private_2a_subnet_id
#   user_data_base64       = base64encode(local.instance-userdata)
#   iam_instance_profile   = aws_iam_instance_profile.instance_profile.id
#   tags = {
#     Name = "${local.environment}-landingzone-httptest"
#     # Environment = "dev"
#     Environment = local.environment
#   }
# }
#
# resource "aws_iam_instance_profile" "instance_profile" {
#   name = "SsmManagedInstanceProfile"
#   role = aws_iam_role.ssm_managed_instance.name
# }
#
# resource "aws_iam_role" "ssm_managed_instance" {
#   name                = "SsmManagedInstance"
#   managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
#   assume_role_policy  = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Principal": {
#                 "Service": "ec2.amazonaws.com"
#             },
#             "Action": "sts:AssumeRole"
#         }
#     ]
# }
# EOF
# }
#
# module "httptest_sg" {
#   source      = "terraform-aws-modules/security-group/aws"
#   version     = "~> 4.0"
#   name        = "landingzone-httptest-sg"
#   description = "Security group for TG connectivity testing between LAA LZ & MP"
#   vpc_id      = local.application_data.accounts[local.environment].mp_vpc_id
#   egress_with_cidr_blocks = [
#     {
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       description = "Outgoing"
#       cidr_blocks = "0.0.0.0/0"
#     }
#   ]
#   ingress_with_cidr_blocks = [
#     {
#       from_port   = 80
#       to_port     = 80
#       protocol    = "tcp"
#       description = "HTTP"
#       cidr_blocks = "10.200.0.0/20"
#     },
#     {
#       from_port   = 80
#       to_port     = 80
#       protocol    = "tcp"
#       description = "HTTP"
#       cidr_blocks = local.application_data.accounts[local.environment].lz_vpc_cidr
#     }
#   ]
#   ingress_with_source_security_group_id = [
#     {
#       from_port   = 443
#       to_port     = 443
#       protocol    = "tcp"
#       description = "HTTPS For SSM Session Manager"
#       # source_security_group_id = "sg-0754d9a309704addd" # laa interface endpoint security group in core-vpc-development
#       source_security_group_id = local.application_data.accounts[local.environment].mp_laa_int_endpoint_security_group
#     }
#   ]
# }
