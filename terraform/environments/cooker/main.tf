###########################################################################################
#------------------------Comment out file if not required----------------------------------
###########################################################################################


locals {

  app_name = "ec2-test-instance"
  business_unit       = var.networking[0].business-unit
  region              = "eu-west-2"

  instance = {
    disable_api_termination      = false
    key_name                     = try(aws_key_pair.ec2-user.key_name)
    monitoring                   = false
    metadata_options_http_tokens = "required"
    vpc_security_group_ids       = try([aws_security_group.example_ec2_sg.id])
  }

  ec2_test = {

    tags = {
      component = "example-ec2-build-using-module"
    }

    route53_records = {
      create_internal_record = false
      create_external_record = false
    }

    ec2_instances = {

      example-1 = {
        tags = {
          server-type = "private"
          description = "ec2-example-1"
          monitored   = false
          os-type     = "Linux"
          component   = "ndh"
          environment = "development"
        }
        ebs_volumes = {
          "/dev/sdf" = { size = 20 }
        }
        ami_name  = "amzn2-ami-kernel-5.10-hvm-2.0.20240131.0-x86_64-gp2"
        ami_owner = "137112412989"
        subnet_id = data.aws_subnet.private_subnets_a.id
        availability_zone = "eu-west-2a"
        instance_type = "t3.small"
        user_data = <<EOF
            #!/bin/bash
            yum update -y
            yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
            systemctl status amazon-ssm-agent
            yum install httpd -y
            systemctl start httpd
            EOF
      }

      example-2 = {
        tags = {
          server-type = "private"
          description = "ec2-example-2"
          monitored   = false
          os-type     = "Linux"
          component   = "ndh"
          environment = "development"
        }
        ebs_volumes = {
          "/dev/sdf" = { size = 20 }
        }
        ami_name  = "amzn2-ami-kernel-5.10-hvm-2.0.20240131.0-x86_64-gp2"
        ami_owner = "137112412989"
        subnet_id = data.aws_subnet.private_subnets_b.id
        availability_zone = "eu-west-2b"
        instance_type = "t3.micro"
        user_data = <<EOF
            #!/bin/bash
            yum update -y
            yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
            systemctl status amazon-ssm-agent
            EOF
      }

    }
  
  }

  # This local provides a list of ingress rules for the ec2 security groups.

  example_ec2_sg_ingress_rules = {

    TCP_22 = {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      cidr_block = data.aws_vpc.shared.cidr_block
    }

    TCP_443 = {
      from_port = 443
      to_port = 443
      protocol = "TCP"
      cidr_block = data.aws_vpc.shared.cidr_block
    }

  }

  example_ec2_sg_egress_rules = {

    TCP_ALL = {
      from_port = 1
      to_port = 65000
      protocol = "TCP"
      cidr_block = "0.0.0.0/0"
    }

  }

  # create list of common managed policies that can be attached to ec2 instance profiles
  ec2_common_managed_policies = [
    aws_iam_policy.ec2_common_policy.arn
  ]

}


# EC2 Created via module
module "ec2_instance" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v2.4.1"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }
  for_each                      = try(local.ec2_test.ec2_instances, {})
  name                          = each.key
  ami_name                      = each.value.ami_name
  ami_owner                     = try(each.value.ami_owner, "core-shared-services-production")
  instance                      = merge(local.instance, lookup(each.value, "instance", { disable_api_stop = false, instance_type = try(each.value.instance_type) }))
  ebs_volumes_copy_all_from_ami = try(each.value.ebs_volumes_copy_all_from_ami, true)
  ebs_kms_key_id                = "" # module.environment.kms_keys["ebs"].arn
  ebs_volume_config             = lookup(each.value, "ebs_volume_config", {})
  ebs_volumes                   = lookup(each.value, "ebs_volumes", {})
  ssm_parameters_prefix         = lookup(each.value, "ssm_parameters_prefix", "example-ec2/")
  ssm_parameters                = lookup(each.value, "ssm_parameters", null)
  route53_records               = merge(local.ec2_test.route53_records, lookup(each.value, "route53_records", {}))
  availability_zone        = each.value.availability_zone
  subnet_id                = each.value.subnet_id
  iam_resource_names_prefix = local.app_name
  instance_profile_policies = local.ec2_common_managed_policies
  business_unit            = local.business_unit
  application_name         = local.application_name
  environment              = local.environment
  region                   = local.region
  tags                     = merge(local.tags, local.ec2_test.tags, try(each.value.tags, {}))
  account_ids_lookup       = local.environment_management.account_ids
  user_data_raw            = try(each.value.user_data, "")
  cloudwatch_metric_alarms = {}
}

###### EC2 Security Group ######

resource "aws_security_group" "example_ec2_sg" {
  name        = "example_ec2_sg"
  description = "Controls access to EC2"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-example", local.application_name, local.environment)) }
  )
}

resource "aws_security_group_rule" "ingress_traffic" {
  for_each          = local.example_ec2_sg_ingress_rules
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.example_ec2_sg.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [each.value.cidr_block]
}

resource "aws_security_group_rule" "egress_traffic" {
  for_each                 = local.example_ec2_sg_egress_rules
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.example_ec2_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  cidr_blocks       = [each.value.cidr_block]
}


# create single managed policy
resource "aws_iam_policy" "ec2_common_policy" {
  name        = "ec2-common-policy"
  path        = "/"
  description = "Common policy for all ec2 instances"
  policy      = data.aws_iam_policy_document.ec2_common_combined.json
  tags = merge(
    local.tags,
    {
      Name = "ec2-common-policy"
    },
  )
}

# combine ec2-common policy documents
data "aws_iam_policy_document" "ec2_common_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.ec2_policy.json,
  ]
}

# custom policy for SSM as managed policy AmazonSSMManagedInstanceCore is too permissive
data "aws_iam_policy_document" "ec2_policy" {
  statement {
    sid    = "CustomEc2Policy"
    effect = "Allow"
    actions = [
      "s3:List*"
    ]
    resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
  }
}


# Required.
data "aws_kms_key" "default_ebs" {
  key_id = "alias/aws/ebs"
}

#------------------------------------------------------------------------------
# Keypair for ec2-user
#------------------------------------------------------------------------------
resource "aws_key_pair" "ec2-user" {
  key_name   = "ec2-user"
  public_key = file(".ssh/${terraform.workspace}/ec2-user.pub")
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ec2-user"
    },
  )
}

#### This file can be used to store data specific to the member account ####
data "aws_iam_policy_document" "ebs-kms" {
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_109
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [
      "ec2.amazonaws.com"]
    }
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
      "arn:aws:iam::${data.aws_caller_identity.original_session.id}:root"]
    }
  }
}

