##
# Local vars for ec2
##
locals {

  ec2_tags = merge(local.tags, {
    Name = lower(format("%s-%s", local.application_name, local.environment))
  })

  # Set of log groups references by the clouda watch agent config
  cloudwatch_agent_log_group_names = [
    "amazon-cloudwatch-agent.log",
    "access.log",
    "error.log",
    "ndinterface/xmltransfer.log",
    "ndinterface/daysummary.log",
    "iminterface/imiapsif.log",
    "system-events",
    "application-events"
  ]

  iaps_server = {

    instance = {
      disable_api_termination      = false
      instance_type                = local.application_data.accounts[local.environment].ec2_iaps_instance_type
      key_name                     = "ec2-user"
      monitoring                   = true
      metadata_options_http_tokens = "required"
      vpc_security_group_ids       = [aws_security_group.iaps.id]
    }

    # the ami has got unwanted ephemeral devices so don't copy these
    ebs_volumes_copy_all_from_ami = false

    ebs_volumes = {
      "/dev/sda1" = {
        type = "gp3"
        size = "50"
      }

      // unmount volume from parent AMI
      // that was used to enable windows features
      // without needing to go out to the internet.
      "/dev/xvdf" = {
        no_device = true
      }
    }

    user_data_raw = base64encode(
      templatefile(
        "${path.module}/templates/iaps-EC2LaunchV2.yaml.tftpl",
        {
          delius_iaps_ad_password_secret_name = aws_secretsmanager_secret.ad_password.name
          delius_iaps_ad_domain_name          = aws_directory_service_directory.active_directory.name
          delius_iaps_rds_db_address          = aws_db_instance.iaps.address
          ndelius_interface_url               = local.application_data.accounts[local.environment].iaps_ndelius_interface_url
          im_interface_url                    = local.application_data.accounts[local.environment].iaps_im_interface_url
          im_db_url                           = local.application_data.accounts[local.environment].iaps_im_db_url

          # TODO: remove environment variable and related conditional statements
          # temporarily needed to ensure no connections to delius and im are attempted
          environment = local.environment
        }
      )
    )

    autoscaling_group = {
      desired_capacity = 1
      max_size         = 1
      min_size         = 1
      force_delete     = true
    }

    iam_policies = [
      aws_iam_policy.iaps_ec2_policy.arn,
      aws_iam_policy.ssm_least_privilege_policy.arn,
      "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy" # Managed policy for cloudwatch agent to talk to CloudWatch
    ]

  }

}

##
# Data
## 
# Can use aws ec2 describe-images --filters "Name=owner-id,Values=374269020027" --filters "Name=description,Values='Delius IAPS server'" --query 'reverse(sort_by(Images, &CreationDate))[0].[Name,ImageId]' to test
# data "aws_ami" "delius_iaps_server" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["${local.application_data.accounts}*"]
#   }

#   owners = [local.environment_management.account_ids["core-shared-services-production"]]
# }

##
# Resources - Dependencies for ASG and launch template
##
resource "aws_key_pair" "ec2-user" {
  key_name   = local.iaps_server.instance.key_name
  public_key = file(".ssh/${terraform.workspace}/ec2-user.pub")
  tags = merge(
    local.ec2_tags,
    {
      Name = "ec2-user"
    }
  )
}

#checkov:skip=CKV2_AWS_5
resource "aws_security_group" "iaps" {
  name        = lower(format("%s-%s", local.application_name, local.environment))
  description = "Controls access to IAPS EC2 instance"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.ec2_tags
}

resource "aws_security_group_rule" "ingress_traffic_vpc" {
  for_each          = local.application_data.iaps_sg_ingress_rules_vpc
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.iaps.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "egress_traffic_cidr" {
  for_each          = local.application_data.iaps_sg_egress_rules_cidr
  description       = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.iaps.id
  to_port           = each.value.to_port
  type              = "egress"
  cidr_blocks       = [each.value.destination_cidr]
}

resource "aws_security_group_rule" "egress_traffic_ad" {
  for_each                 = local.application_data.iaps_sg_egress_rules_ad
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.iaps.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_directory_service_directory.active_directory.security_group_id
}

data "aws_iam_policy_document" "iaps_ec2_assume_role_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "iaps_ec2_policy" {
  statement {
    sid = "SecretPermissions"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [aws_secretsmanager_secret.ad_password.arn]
  }
}

resource "aws_iam_policy" "iaps_ec2_policy" {
  name        = "read-access-to-bucket-and-secrets"
  path        = "/"
  description = "Allow iaps server to read bucket objects and secrets"
  policy      = data.aws_iam_policy_document.iaps_ec2_policy.json
  tags = merge(
    local.tags,
    {
      Name = "read-access-to-bucket-and-secrets-policy"
    }
  )
}

data "aws_iam_policy_document" "ssm_least_privilege_policy" {
  statement {
    sid    = "CustomSsmPolicy"
    effect = "Allow"
    actions = [
      "ssm:DescribeAssociation",
      "ssm:DescribeDocument",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]
    # skipping these as policy is a scoped down version of Amazon provided AmazonSSMManagedInstanceCore managed policy.  Permissions required for SSM function

    #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
    #checkov:skip=CKV_AWS_108: "Ensure IAM policies does not allow data exfiltration"
    resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
  }
}

resource "aws_iam_policy" "ssm_least_privilege_policy" {
  name        = "ssm-least-privilege-policy"
  path        = "/"
  description = "Least privilege policy for ec2 to interact with SSM"
  policy      = data.aws_iam_policy_document.ssm_least_privilege_policy.json
  tags = merge(
    local.tags,
    {
      Name = "ssm_least_privilege_policy"
    },
  )
}
# resource "aws_iam_role" "iaps_ec2_role" {
#   name                = "iaps_ec2_role"
#   assume_role_policy  = data.aws_iam_policy_document.iaps_ec2_assume_role_policy.json
#   managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
#   inline_policy {
#     name   = "IapsEc2Policy"
#     policy = data.aws_iam_policy_document.iaps_ec2_policy.json
#   }
#   tags = merge(
#     local.ec2_tags,
#     {
#       Name = "iaps_ec2_role"
#     },
#   )
# }

# resource "aws_iam_instance_profile" "iaps_ec2_profile" {
#   name = "iaps_ec2_profile"
#   role = aws_iam_role.iaps_ec2_role.name
# }



##
# Resources - Create ASG and launch template using module
##
module "ec2_iaps_server" {
  source = "../../modules/ec2_autoscaling_group"


  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  name                          = local.application_data.ec2_iaps_instance_label
  ami_name                      = local.application_data.ec2_iaps_instance_ami_name
  ami_owner                     = local.application_data.ec2_iaps_instance_ami_owner
  instance                      = local.iaps_server.instance
  user_data_raw                 = local.iaps_server.user_data_raw
  ebs_volumes_copy_all_from_ami = local.iaps_server.ebs_volumes_copy_all_from_ami
  ebs_volume_config             = {}
  ebs_volumes                   = local.iaps_server.ebs_volumes
  ssm_parameters                = null
  autoscaling_group             = local.iaps_server.autoscaling_group
  autoscaling_schedules         = {}
  # NOMIS example 
  # autoscaling_schedules = coalesce(lookup(each.value, "autoscaling_schedules", null), {
  #   # if sizes not set, use the values defined in autoscaling_group
  #   "scale_up" = {
  #     recurrence = "0 7 * * Mon-Fri"
  #   }
  #   "scale_down" = {
  #     desired_capacity = lookup(each.value, "offpeak_desired_capacity", 0)
  #     recurrence       = "0 19 * * Mon-Fri"
  #   }
  # })

  instance_profile_policies = local.iaps_server.iam_policies
  application_name          = local.application_name
  region                    = data.aws_region.current.name
  subnet_ids                = data.aws_subnets.private-public.ids
  tags                      = local.ec2_tags
  account_ids_lookup        = local.environment_management.account_ids
}

##
# Set up cloud watch log groups (referenced by the cloud watch agent to send events to log streams in the group)
##
resource "aws_cloudwatch_log_group" "cloudwatch_agent_log_groups" {
  for_each          = toset(local.cloudwatch_agent_log_group_names)
  name              = "/iaps/${each.key}"
  retention_in_days = local.application_data.accounts[local.environment].cloudwatch_agent_log_group_retention_period
  tags = merge(
    local.ec2_tags,
    {
      "Name" = "iaps/${each.key}"
  })
}
