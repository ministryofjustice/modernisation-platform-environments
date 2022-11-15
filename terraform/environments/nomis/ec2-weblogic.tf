#------------------------------------------------------------------------------
# Weblogic
#------------------------------------------------------------------------------

locals {

  ec2_weblogic = {

    # server-type and nomis-environment auto set by module
    tags = {
      description = "nomis weblogic appserver 10.3"
      component   = "web"
    }

    instance = {
      disable_api_termination      = false
      instance_type                = "t2.large"
      key_name                     = aws_key_pair.ec2-user.key_name
      monitoring                   = true
      metadata_options_http_tokens = "optional"
      vpc_security_group_ids       = [aws_security_group.weblogic_common.id]
    }

    user_data = {
      args = {
        lifecycle_hook_name = "ready-hook"
      }
      scripts = [
        "ansible-ec2provision.sh.tftpl",
        "post-ec2provision.sh.tftpl"
      ]
      write_files = {}
    }

    autoscaling_group = {
      desired_capacity = 1
      max_size         = 2
      min_size         = 0

      health_check_grace_period = 300
      health_check_type         = "ELB"
      force_delete              = true
      termination_policies      = ["OldestInstance"]
      target_group_arns         = [] # TODO
      vpc_zone_identifier       = data.aws_subnets.private.ids
      wait_for_capacity_timeout = 0

      # this hook is triggered by the post-ec2provision.sh
      initial_lifecycle_hooks = {
        "ready-hook" = {
          default_result       = "ABANDON"
          heartbeat_timeout    = 7200 # on a good day it takes 30 mins, but can be much longer
          lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
        }
      }
      warm_pool = {
        reuse_on_scale_in           = true
        max_group_prepared_capacity = 1
      }

      instance_refresh = {
        strategy               = "Rolling"
        min_healthy_percentage = 90 # seems that instances in the warm pool are included in the % health count so this needs to be set fairly high
        instance_warmup        = 300
      }
    }
  }
}

module "weblogic" {
  source = "./modules/weblogic"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = local.environment_config.weblogics

  name = each.key

  ami_name             = each.value.ami_name
  asg_max_size         = try(each.value.asg_max_size, null)
  asg_min_size         = try(each.value.asg_min_size, null)
  asg_desired_capacity = try(each.value.asg_desired_capacity, null)

  ami_owner              = try(each.value.ami_owner, local.environment_management.account_ids["core-shared-services-production"])
  termination_protection = try(each.value.termination_protection, null)

  common_security_group_id   = aws_security_group.weblogic_common.id
  instance_profile_policies  = local.ec2_common_managed_policies
  key_name                   = aws_key_pair.ec2-user.key_name
  load_balancer_listener_arn = aws_lb_listener.internal.arn

  application_name = local.application_name
  business_unit    = local.vpc_name
  environment      = local.environment
  tags             = local.tags
  subnet_set       = local.subnet_set
}

module "ec2_weblogic_autoscaling_group" {
  source = "./modules/ec2_autoscaling_group"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = try(local.environment_config.weblogic_autoscaling_groups, {})

  name = each.key

  ami_name              = each.value.ami_name
  ami_owner             = try(each.value.ami_owner, "core-shared-services-production")
  instance              = merge(local.ec2_weblogic.instance, lookup(each.value, "instance", {}))
  user_data             = merge(local.ec2_weblogic.user_data, lookup(each.value, "user_data", {}))
  ebs_volume_config     = lookup(each.value, "ebs_volume_config", {})
  ebs_volumes           = lookup(each.value, "ebs_volumes", {})
  ssm_parameters_prefix = "weblogic/"
  ssm_parameters        = {}
  autoscaling_group     = merge(local.ec2_weblogic.autoscaling_group, lookup(each.value, "autoscaling_group", {}))
  autoscaling_schedules = coalesce(lookup(each.value, "autoscaling_schedules", null), {
    # if sizes not set, use the values defined in autoscaling_group
    "scale_up" = {
      recurrence = "0 7 * * Mon-Fri"
    }
    "scale_down" = {
      desired_capacity = lookup(each.value, "offpeak_desired_capacity", 0)
      recurrence       = "0 19 * * Mon-Fri"
    }
  })


  iam_resource_names_prefix = "ec2-weblogic-asg"
  instance_profile_policies = local.ec2_common_managed_policies

  business_unit      = local.vpc_name
  application_name   = local.application_name
  environment        = local.environment
  region             = local.region
  availability_zone  = local.availability_zone
  subnet_set         = local.subnet_set
  subnet_name        = "private"
  tags               = merge(local.tags, local.ec2_test.tags, try(each.value.tags, {}))
  account_ids_lookup = local.environment_management.account_ids

  ansible_repo         = "modernisation-platform-configuration-management"
  ansible_repo_basedir = "ansible"
  branch               = try(each.value.branch, "main")
}

#  load_balancer_listener_arn = aws_lb_listener.internal.arn

#------------------------------------------------------------------------------
# Common Security Group for Weblogic Instances
#------------------------------------------------------------------------------

resource "aws_security_group" "weblogic_common" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource" - attached in nomis-stack module
  description = "Common security group for weblogic instances"
  name        = "weblogic-common"
  vpc_id      = local.vpc_id

  ingress {
    description     = "SSH from Bastion"
    from_port       = "22"
    to_port         = "22"
    protocol        = "TCP"
    security_groups = [module.bastion_linux.bastion_security_group]
  }

  ingress {
    description     = "access from Windows Jumpserver (admin console)"
    from_port       = "7001"
    to_port         = "7001"
    protocol        = "TCP"
    security_groups = [aws_security_group.jumpserver-windows.id]
  }

  ingress {
    description     = "access from Windows Jumpserver"
    from_port       = "80"
    to_port         = "80"
    protocol        = "TCP"
    security_groups = [aws_security_group.jumpserver-windows.id]
  }

  ingress {
    description = "access from Windows Jumpserver and loadbalancer (forms/reports)"
    from_port   = "7777"
    to_port     = "7777"
    protocol    = "TCP"
    security_groups = [
      aws_security_group.jumpserver-windows.id,
      # TODO: Add a 'security_group_id' output to the MP load balancer module.
      # Hardcoding as a string for now.
      "sg-075cf385b5a966b04"
    ]
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
      Name = "weblogic-commmon"
    }
  )
}
