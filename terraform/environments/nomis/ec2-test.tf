#------------------------------------------------------------------------------
# EC2 Instances following naming convention
#------------------------------------------------------------------------------

# SET TAGS
locals {

  # user can manually increase the desired capacity to 1 via CLI/console 
  # to create an instance
  ec2_test_autoscaling_group = {
    desired_capacity = 0
    max_size         = 2
    min_size         = 0
  }

  ec2_test = {

    # server-type and nomis-environment auto set by module
    tags = {
      component = "test"
    }

    instance = {
      disable_api_termination      = false
      instance_type                = "t3.medium"
      key_name                     = aws_key_pair.ec2-user.key_name
      monitoring                   = false
      metadata_options_http_tokens = "required"
      vpc_security_group_ids       = [aws_security_group.ec2_test.id]
      private_dns_name_options = {
        hostname_type = "resource-name"
      }
    }

    ebs_volume_config = {}
    ebs_volumes       = {}
    ssm_parameters    = {}

    user_data = {
      scripts     = ["ansible-ec2provision.sh.tftpl"]
      write_files = {}
    }

    route53_records = {
      create_internal_record = true
      create_external_record = false
    }

    autoscaling_group = local.ec2_test_autoscaling_group

    autoscaling_lifecycle_hooks = {}

    autoscaling_schedules = {
      # if sizes not set, use the values defined in autoscaling_group
      "scale_up" = {
        recurrence = "0 7 * * Mon-Fri"
      }
      "scale_down" = {
        min_size         = 0
        max_size         = 0
        desired_capacity = 0
        recurrence       = "0 19 * * Mon-Fri"
      }
    }
  }
}

module "ec2_test_instance" {
  source = "./modules/ec2_instance"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = try(local.environment_config.ec2_test_instances, {})

  name = each.key

  ami_name              = each.value.ami_name
  ami_owner             = local.account_id
  instance              = merge(local.ec2_test.instance, lookup(each.value, "instance", {}))
  user_data             = merge(local.ec2_test.user_data, lookup(each.value, "user_data", {}))
  ebs_volume_config     = merge(local.ec2_test.ebs_volume_config, lookup(each.value, "ebs_volume_config", {}))
  ebs_volumes           = { for k, v in local.ec2_test.ebs_volumes : k => merge(v, try(each.value.ebs_volumes[k], {})) }
  ssm_parameters_prefix = "test/"
  ssm_parameters        = merge(local.ec2_test.ssm_parameters, lookup(each.value, "ssm_parameters", {}))
  route53_records       = merge(local.ec2_test.route53_records, lookup(each.value, "route53_records", {}))

  iam_resource_names_prefix = "ec2-test-instance"
  instance_profile_policies = local.ec2_common_managed_policies

  business_unit     = local.vpc_name
  application_name  = local.application_name
  environment       = local.environment
  region            = local.region
  availability_zone = local.availability_zone
  subnet_set        = local.subnet_set
  subnet_name       = "private"
  tags              = merge(local.tags, local.ec2_test.tags, try(each.value.tags, {}))

  ansible_repo         = "modernisation-platform-configuration-management"
  ansible_repo_basedir = "ansible"
  branch               = try(each.value.branch, "main")
}

module "ec2_test_autoscaling_group" {
  source = "./modules/ec2_autoscaling_group"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = try(local.environment_config.ec2_test_autoscaling_groups, {})

  name = each.key

  ami_name                    = each.value.ami_name
  ami_owner                   = local.account_id
  instance                    = merge(local.ec2_test.instance, lookup(each.value, "instance", {}))
  user_data                   = merge(local.ec2_test.user_data, lookup(each.value, "user_data", {}))
  ebs_volume_config           = merge(local.ec2_test.ebs_volume_config, lookup(each.value, "ebs_volume_config", {}))
  ebs_volumes                 = { for k, v in local.ec2_test.ebs_volumes : k => merge(v, try(each.value.ebs_volumes[k], {})) }
  autoscaling_group           = merge(local.ec2_test.autoscaling_group, lookup(each.value, "autoscaling_group", {}))
  autoscaling_lifecycle_hooks = merge(local.ec2_test.autoscaling_lifecycle_hooks, lookup(each.value, "autoscaling_lifecycle_hooks", {}))
  autoscaling_schedules       = coalesce(lookup(each.value, "autoscaling_schedules", null), local.ec2_test.autoscaling_schedules)

  iam_resource_names_prefix = "ec2-test-asg"
  instance_profile_policies = local.ec2_common_managed_policies

  business_unit     = local.vpc_name
  application_name  = local.application_name
  environment       = local.environment
  region            = local.region
  availability_zone = local.availability_zone
  subnet_set        = local.subnet_set
  subnet_name       = "data"
  tags              = merge(local.tags, local.ec2_test.tags, try(each.value.tags, {}))

  ansible_repo         = "modernisation-platform-configuration-management"
  ansible_repo_basedir = "ansible"
  branch               = try(each.value.branch, "main")
}

#------------------------------------------------------------------------------
# Common Security Group for Test Instances
#------------------------------------------------------------------------------

resource "aws_security_group" "ec2_test" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource" - attached in nomis-stack module
  description = "Security group for ec2_test instances"
  name        = "ec2_test"
  vpc_id      = data.aws_vpc.shared_vpc.id

  ingress {
    description     = "SSH from Bastion"
    from_port       = "22"
    to_port         = "22"
    protocol        = "TCP"
    security_groups = [module.bastion_linux.bastion_security_group]
  }

  ingress {
    description = "access from Cloud Platform Prometheus server"
    from_port   = "9100"
    to_port     = "9100"
    protocol    = "TCP"
    cidr_blocks = [local.cidrs.cloud_platform]
  }

  ingress {
    description = "access from Cloud Platform Prometheus script exporter collector"
    from_port   = "9172"
    to_port     = "9172"
    protocol    = "TCP"
    cidr_blocks = [local.cidrs.cloud_platform]
  }

  egress {
    description = "allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "ec2-test-common"
    }
  )
}

