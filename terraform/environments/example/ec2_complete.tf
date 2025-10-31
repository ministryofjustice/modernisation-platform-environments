# ##########################################################################################
# # ------------------------Comment out file if not required----------------------------------
# ##########################################################################################

# This self-contained example can be used to create EC2 instances using this module. Explanatory notes have been added
# that cover the key elements as well as known limitations & issues. This example was developed and tested using the cooker environment
# but should work just as well in any other member environment in modernisation-platform-environments.

# NOTE - the example includes a reference to a public key "ec2-user.pub" in the directory ".ssh/${terraform.workspace}". Amend this directory
# as required to refer to the public part of the key pair to be used.


#------------------------------------------------------------------------------
# Keypair for ec2-user
#------------------------------------------------------------------------------
# resource "aws_key_pair" "ec2-user-complete" {
#   key_name   = "ec2-user-complete"
#   public_key = file(".ssh/${terraform.workspace}/ec2-user.pub")
#   tags       = { Name = "${local.application_name}-ec2-user-complete" }
# }

# # This locals block contains variables required to create ec2 instances using the module.

# locals {

#   comp_app_name      = "ec2-complete" # This is used as the primary label to desribe the resources.
#   comp_business_unit = var.networking[0].business-unit
#   comp_region        = "eu-west-2"


#   # This local is used by the module variable "instance".  
#   instance_complete = {
#     disable_api_termination      = false
#     key_name                     = try(aws_key_pair.ec2-user-complete.key_name)
#     monitoring                   = false
#     metadata_options_http_tokens = "required"
#     vpc_security_group_ids       = try([aws_security_group.example_ec2_sg.id])
#   }

#   # This local block contains the variables required to build one of more ec2s. 
#   ec2_var = {

#     tags = {
#       component = "ec2-complete-example-using-module"
#     }

#     # The object ec2_instances requires one or more sub objects to be created. The key of each object (e.g. example-1) will
#     # be used for 'Name' tag values as well as prefix of R53 records (see above). Each contains an example of user-data and adds a 2nd
#     # ebs volume to the ec2 using the ebs_volumes local.

#     ec2_complete = {

#       complete-example-1 = { # The first ec2.
#         tags = {
#           server-type         = "private"
#           description         = "ec2-complete-example-1"
#           monitored           = false
#           os-type             = "Linux"
#           component           = "ndh"
#           environment         = "development"
#           flexi-startup       = "8am"
#           flexi-shutdown      = "7pm"
#           instance-scheduling = "skip-scheduling"
#         }
#         ebs_volumes = {
#           "/dev/sdf" = { size = 20, type = "gp3" }
#         }
#         ami_name          = "amzn2-ami-kernel-5.10-hvm-2.0.20240131.0-x86_64-gp2" # Note the module requires the AMI name, not the ID.
#         ami_owner         = "137112412989"
#         subnet_id         = data.aws_subnet.private_subnets_a.id # This example creates the ec2 in a private subnet.
#         availability_zone = "eu-west-2a"
#         instance_type     = "t3.small"
#         user_data         = <<EOF
#             #!/bin/bash
#             yum update -y
#             yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
#             systemctl status amazon-ssm-agent
#             yum install httpd -y
#             systemctl start httpd
#             EOF
#         # Route53 DNS Records - the prefix for these is derrived from key of the ec2_instances list below.
#         route53_records = {
#           create_internal_record = true
#           create_external_record = false
#         }
#       }

#       complete-example-2 = { # The second ec2.
#         tags = {
#           server-type         = "private"
#           description         = "ec2-complete-example-2"
#           monitored           = false
#           os-type             = "Linux"
#           component           = "ndh"
#           environment         = "development"
#           flexi-startup       = "8am"
#           flexi-shutdown      = "7pm"
#           instance-scheduling = "skip-scheduling"
#         }
#         ebs_volumes = {
#           "/dev/sdf" = { size = 20, type = "gp3" }
#         }
#         ami_name          = "amzn2-ami-kernel-5.10-hvm-2.0.20240131.0-x86_64-gp2"
#         ami_owner         = "137112412989"
#         subnet_id         = data.aws_subnet.private_subnets_b.id
#         availability_zone = "eu-west-2b"
#         instance_type     = "t3.micro"
#         user_data         = <<EOF
#             #!/bin/bash
#             yum update -y
#             yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
#             systemctl status amazon-ssm-agent
#             EOF
#         route53_records = {
#           create_internal_record = false
#           create_external_record = false
#         }
#       }
#     }
#   }

#   # This local provides a list of ingress and egress rules for the ec2 security group.

#   complete_ec2_sg_ingress_rules = {
#     TCP_22 = {
#       from_port  = 22
#       to_port    = 22
#       protocol   = "TCP"
#       cidr_block = data.aws_vpc.shared.cidr_block
#     }
#     TCP_443 = {
#       from_port  = 443
#       to_port    = 443
#       protocol   = "TCP"
#       cidr_block = data.aws_vpc.shared.cidr_block
#     }
#   }

#   complete_ec2_sg_egress_rules = {
#     TCP_ALL = {
#       from_port  = 1
#       to_port    = 65000
#       protocol   = "TCP"
#       cidr_block = "0.0.0.0/0"
#     }
#   }

#   # create list of common managed policies that can be attached to ec2 instance profiles
#   ec2_complete_common_managed_policies = [
#     aws_iam_policy.ec2_common_policy.arn
#   ]

# }

# # This item is used to combine multiple policy documents though for this example only one policy document is created.
# data "aws_iam_policy_document" "ec2_complete_common_combined" {
#   source_policy_documents = [
#     data.aws_iam_policy_document.ec2_complete_policy.json
#   ]
# }

# # This policy document is added as an example. Note that the module does not support access via AWS Session Manager.
# data "aws_iam_policy_document" "ec2_complete_policy" {
#   #checkov:skip=CKV_AWS_111
#   #checkov:skip=CKV_AWS_356
#   statement {
#     sid    = "AllowSSMAccess"
#     effect = "Allow"
#     actions = [
#       "ssm:StartSession",
#       "ssm:ResumeSession",
#       "ssm:TerminateSession",
#       "ssmmessages:CreateControlChannel",
#       "ssmmessages:CreateDataChannel",
#       "ssmmessages:OpenControlChannel",
#       "ssmmessages:OpenDataChannel",
#       "ec2messages:AcknowledgeMessage",
#       "ec2:DescribeInstances"
#     ]
#     resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
#   }
# }

# This is the main call to the module. Note the for_each loop.
# module "ec2_complete_instance" {
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=edc55b4005b7039e5b54ad7805e89a473fe3c3dd" # v2.4.1

#   providers = {
#     aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
#   }
#   for_each                      = try(local.ec2_var.ec2_complete, {}) # Iterates through each element of ec2_instances.
#   application_name              = local.comp_app_name
#   name                          = each.key
#   ami_name                      = each.value.ami_name
#   ami_owner                     = try(each.value.ami_owner, "core-shared-services-production")
#   instance                      = merge(local.instance_complete, lookup(each.value, "instance", { disable_api_stop = false, instance_type = try(each.value.instance_type) }))
#   ebs_volumes_copy_all_from_ami = try(each.value.ebs_volumes_copy_all_from_ami, true)
#   ebs_kms_key_id                = "" # Suggest there that the default ebs key for the account is used instead as a default entry.
#   ebs_volume_config             = lookup(each.value, "ebs_volume_config", {})
#   ebs_volumes                   = lookup(each.value, "ebs_volumes", {})
#   route53_records               = lookup(each.value, "route53_records", {})
#   availability_zone             = each.value.availability_zone
#   subnet_id                     = each.value.subnet_id
#   iam_resource_names_prefix     = local.comp_app_name
#   instance_profile_policies     = local.ec2_complete_common_managed_policies
#   business_unit                 = local.comp_business_unit
#   environment                   = local.environment
#   region                        = local.comp_region
#   tags                          = merge(local.ec2_test.tags, try(each.value.tags, {}))
#   account_ids_lookup            = local.environment_management.account_ids
#   user_data_raw                 = try(each.value.user_data, "")
#   cloudwatch_metric_alarms      = {}
# }

###### EC2 Security Groups ######

# Creates a single security group to be used by all the ec2s defined here with ingress & egress rules using the 'example_ec2_sg_ingress_rules' local.

# resource "aws_security_group" "complete_example_ec2_sg" {
#   name        = "complete_ec2_sg"
#   description = "Ingress and Egress Access Controls for EC2"
#   vpc_id      = data.aws_vpc.shared.id
#   tags        = { Name = lower(format("sg-%s-%s-example", local.application_name, local.environment)) }
# }

# resource "aws_security_group_rule" "complete_ingress_traffic" {
#   for_each          = local.complete_ec2_sg_ingress_rules
#   description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
#   from_port         = each.value.from_port
#   protocol          = each.value.protocol
#   security_group_id = aws_security_group.example_ec2_sg.id
#   to_port           = each.value.to_port
#   type              = "ingress"
#   cidr_blocks       = [each.value.cidr_block]
# }

# resource "aws_security_group_rule" "complete_egress_traffic" {
#   for_each          = local.complete_ec2_sg_egress_rules
#   description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
#   from_port         = each.value.from_port
#   protocol          = each.value.protocol
#   security_group_id = aws_security_group.example_ec2_sg.id
#   to_port           = each.value.to_port
#   type              = "egress"
#   cidr_blocks       = [each.value.cidr_block]
# }

# ##### IAM Policies #####

# # Creates a single managed policy using the combined policy documents.
# resource "random_id" "ec2_complete_common_policy" {
#   byte_length = 4
# }

# resource "aws_iam_policy" "ec2_complete_common_policy" {
#   name        = "${random_id.ec2_complete_common_policy.dec}-ec2-common-policy"
#   path        = "/"
#   description = "Common policy for all ec2 instances"
#   policy      = data.aws_iam_policy_document.ec2_common_combined.json
#   tags        = { Name = "${random_id.ec2_common_policy.dec}-ec2-common-policy" }
# }