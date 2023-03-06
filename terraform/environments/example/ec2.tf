# First build the security group for the EC2
resource "aws_security_group" "example_ec2_sg" {
  name        = "example_ec2_sg"
  description = "Controls access to EC2"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-example", local.application_name, local.environment)) }
  )
}
resource "aws_security_group_rule" "ingress_traffic" {
  for_each          = local.application_data.example_ec2_sg_rules
  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.example_ec2_sg.id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
}

resource "aws_security_group_rule" "egress_traffic" {
  for_each                 = local.application_data.example_ec2_sg_rules
  description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.example_ec2_sg.id
  to_port                  = each.value.to_port
  type                     = "egress"
  source_security_group_id = aws_security_group.example_ec2_sg.id
}



#  Build EC2 "example-ec2"
resource "aws_instance" "develop" {
  #checkov:skip=CKV2_AWS_41:"IAM role is not implemented for this example EC2. SSH/AWS keys are not used either."
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type          = local.application_data.accounts[local.environment].instance_type
  ami                    = local.application_data.accounts[local.environment].ami_image_id
  vpc_security_group_ids = [aws_security_group.example_ec2_sg.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  monitoring             = true
  ebs_optimized          = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  # Increase the volume size of the root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }
  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-example", local.application_name, local.environment)) }
  )
  depends_on = [aws_security_group.example_ec2_sg]
}



#------------------------------------------------------------------------------
# EC2 Instances following naming convention
#------------------------------------------------------------------------------

locals {
  business_unit       = var.networking[0].business-unit
  region              = "eu-west-2"
  availability_zone_1 = "eu-west-2a"
  availability_zone_2 = "eu-west-2b"
  autoscaling_schedules_default = {
    "scale_up" = {
      recurrence = "0 7 * * Mon-Fri"
    }
    "scale_down" = {
      desired_capacity = 0
      recurrence       = "0 19 * * Mon-Fri"
    }
  }
  ec2_test = {
    tags = {
      component = "test"
    }

    instance = {
      disable_api_termination      = false
      instance_type                = "t3.medium"
      key_name                     = aws_key_pair.ec2-user.key_name
      monitoring                   = false
      metadata_options_http_tokens = "required"
      vpc_security_group_ids       = [aws_security_group.example_ec2_sg.id]
    }

    user_data_cloud_init = {
      args = {
        lifecycle_hook_name  = "ready-hook"
        branch               = "main"
        ansible_repo         = "modernisation-platform-configuration-management"
        ansible_repo_basedir = "ansible"
        ansible_args         = "--tags ec2provision"
      }
      scripts = [
        "install-ssm-agent.sh.tftpl",
        "ansible-ec2provision.sh.tftpl",
        "post-ec2provision.sh.tftpl"
      ]
    }

    route53_records = {
      create_internal_record = true
      create_external_record = false
    }

    # user can manually increase the desired capacity to 1 via CLI/console
    # to create an instance
    autoscaling_group = {
      desired_capacity = 0
      max_size         = 2
      min_size         = 0
    }

    ec2_test_instances = {
      # Remove data.aws_kms_key from cmk.tf once the NDH servers are removed
      example-test-instance-1 = {
        tags = {
          server-type = "private"
          description = "Standalone EC2 for testing RHEL7.9 NDH App"
          monitored   = false
          os-type     = "Linux"
          component   = "ndh"
          environment = "test"
        }
        ebs_volumes = {
          "/dev/sda1" = { kms_key_id = data.aws_kms_key.default_ebs.arn }
        }
        ami_name  = "RHEL-7.9_HVM-*"
        ami_owner = "309956199498"
      }
      example-test-instance-2 = {
        tags = {
          server-type = "private"
          description = "Standalone EC2 for testing RHEL7.9 NDH EMS"
          monitored   = false
          os-type     = "Linux"
          component   = "ndh"
          environment = "test"
        }
        ebs_volumes = {
          "/dev/sda1" = { kms_key_id = data.aws_kms_key.default_ebs.arn }
        }
        ami_name  = "RHEL-7.9_HVM-*"
        ami_owner = "309956199498"
      }
    }
    ec2_test_autoscaling_groups = {
      dev-redhat-rhel610 = {
        tags = {
          description = "For testing official RedHat RHEL6.10 image"
          monitored   = false
          os-type     = "Linux"
          component   = "test"
        }
        instance = {
          instance_type                = "t2.medium"
          metadata_options_http_tokens = "optional"
        }
        ami_name  = "RHEL-6.10_HVM-*"
        ami_owner = "309956199498"
      }
    }
  }
}

data "aws_kms_key" "default_ebs" {
  key_id = "alias/aws/ebs"
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

# create list of common managed policies that can be attached to ec2 instance profiles
locals {
  ec2_common_managed_policies = [
    aws_iam_policy.ec2_common_policy.arn
  ]
}

# custom policy for SSM as managed policy AmazonSSMManagedInstanceCore is too permissive
data "aws_iam_policy_document" "ec2_policy" {
  statement {
    sid    = "CustomEc2Policy"
    effect = "Allow"
    actions = [
      "ec2:*"
    ]
    resources = ["*"] #tfsec:ignore:aws-iam-no-policy-wildcards
  }
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
      Name = "ec2-user"
    },
  )
}

module "ec2_test_instance" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = try(local.ec2_test.ec2_test_instances, {})

  name = each.key

  ami_name                      = each.value.ami_name
  ami_owner                     = try(each.value.ami_owner, "core-shared-services-production")
  instance                      = merge(local.ec2_test.instance, lookup(each.value, "instance", {}))
  ebs_volumes_copy_all_from_ami = try(each.value.ebs_volumes_copy_all_from_ami, true)
  ebs_kms_key_id                = module.environment.kms_keys["ebs"].arn
  ebs_volume_config             = lookup(each.value, "ebs_volume_config", {})
  ebs_volumes                   = lookup(each.value, "ebs_volumes", {})
  ssm_parameters_prefix         = lookup(each.value, "ssm_parameters_prefix", "test/")
  ssm_parameters                = lookup(each.value, "ssm_parameters", null)
  route53_records               = merge(local.ec2_test.route53_records, lookup(each.value, "route53_records", {}))

  iam_resource_names_prefix = "ec2-test-instance"
  instance_profile_policies = local.ec2_common_managed_policies

  business_unit            = local.business_unit
  application_name         = local.application_name
  environment              = local.environment
  region                   = local.region
  availability_zone        = local.availability_zone_1
  subnet_id                = module.environment.subnet["private"][local.availability_zone_1].id
  tags                     = merge(local.tags, local.ec2_test.tags, try(each.value.tags, {}))
  account_ids_lookup       = local.environment_management.account_ids
  cloudwatch_metric_alarms = {}
}

module "ec2_test_autoscaling_group" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-autoscaling-group"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = try(local.ec2_test.ec2_test_autoscaling_groups, {})

  name = each.key

  ami_name                      = each.value.ami_name
  ami_owner                     = try(each.value.ami_owner, "core-shared-services-production")
  instance                      = merge(local.ec2_test.instance, lookup(each.value, "instance", {}))
  ebs_volumes_copy_all_from_ami = try(each.value.ebs_volumes_copy_all_from_ami, true)
  ebs_kms_key_id                = module.environment.kms_keys["ebs"].arn
  ebs_volume_config             = lookup(each.value, "ebs_volume_config", {})
  ebs_volumes                   = lookup(each.value, "ebs_volumes", {})
  ssm_parameters_prefix         = lookup(each.value, "ssm_parameters_prefix", "test/")
  ssm_parameters                = lookup(each.value, "ssm_parameters", null)
  autoscaling_group             = merge(local.ec2_test.autoscaling_group, lookup(each.value, "autoscaling_group", {}))
  autoscaling_schedules         = lookup(each.value, "autoscaling_schedules", local.autoscaling_schedules_default)

  iam_resource_names_prefix = "ec2-test-asg"
  instance_profile_policies = local.ec2_common_managed_policies
  application_name          = local.application_name
  region                    = local.region
  subnet_ids                = module.environment.subnets["private"].ids
  tags                      = merge(local.tags, local.ec2_test.tags, try(each.value.tags, {}))
  account_ids_lookup        = local.environment_management.account_ids
  cloudwatch_metric_alarms  = {}
}
