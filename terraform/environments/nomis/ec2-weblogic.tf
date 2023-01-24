#------------------------------------------------------------------------------
# Weblogic
#------------------------------------------------------------------------------

locals {

  lb_target_group_http_7001 = {
    port                 = 7001
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/"
      port                = 7001
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }

  lb_target_group_http_7777 = {
    port                 = 7777
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/keepalive.htm"
      port                = 7777
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }

  ec2_weblogic = {

    # server-type and nomis-environment auto set by module
    tags = {
      description = "nomis weblogic appserver 10.3"
      os-type     = "Linux"
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

    user_data_cloud_init = {
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
      target_group_arns         = []
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

    lb_target_groups = {}
    #   TODO: create target groups here instead of in load balancer
    #      http-7001 = local.lb_target_group_http_7001
    #      http-7777 = local.lb_target_group_http_7777
  }
}

module "ec2_weblogic_autoscaling_group" {
  source = "../../modules/ec2_autoscaling_group"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = try(local.environment_config.weblogic_autoscaling_groups, {})

  name = each.key

  ami_name                      = each.value.ami_name
  ami_owner                     = try(each.value.ami_owner, "core-shared-services-production")
  instance                      = merge(local.ec2_weblogic.instance, lookup(each.value, "instance", {}))
  user_data_cloud_init          = merge(local.ec2_weblogic.user_data_cloud_init, lookup(each.value, "user_data_cloud_init", {}))
  ebs_volumes_copy_all_from_ami = try(each.value.ebs_volumes_copy_all_from_ami, true)
  ebs_volume_config             = lookup(each.value, "ebs_volume_config", {})
  ebs_volumes                   = lookup(each.value, "ebs_volumes", {})
  ssm_parameters_prefix         = "weblogic/"
  ssm_parameters                = {}
  autoscaling_group             = merge(local.ec2_weblogic.autoscaling_group, lookup(each.value, "autoscaling_group", {}))
  autoscaling_schedules         = lookup(each.value, "autoscaling_schedules", local.autoscaling_schedules_default)
  lb_target_groups              = merge(local.ec2_weblogic.lb_target_groups, lookup(each.value, "lb_target_groups", {}))
  vpc_id                        = local.vpc_id

  iam_resource_names_prefix = "ec2-weblogic-asg"
  instance_profile_policies = local.ec2_common_managed_policies

  application_name   = local.application_name
  region             = local.region
  subnet_ids         = data.aws_subnets.private.ids
  tags               = merge(local.tags, local.ec2_weblogic.tags, try(each.value.tags, {}))
  account_ids_lookup = local.environment_management.account_ids
  branch             = try(each.value.branch, "main")
}

#------------------------------------------------------------------------------
# Common Security Group for Weblogic Instances
#------------------------------------------------------------------------------

resource "aws_security_group" "weblogic_common" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource" - attached in nomis-stack module
  description = "Common security group for weblogic instances"
  name        = "weblogic-common"
  vpc_id      = local.vpc_id

  ingress {
    description = "Internal access to self on all ports"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }

  ingress {
    description = "Internal access to ssh"
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    security_groups = [
      aws_security_group.jumpserver-windows.id,
      module.bastion_linux.bastion_security_group
    ]
  }

  ingress {
    description = "External access to ssh"
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = local.environment_config.external_remote_access_cidrs
  }

  ingress {
    description = "Internal access to Weblogic Admin console"
    from_port   = "7001"
    to_port     = "7001"
    protocol    = "TCP"
    security_groups = concat([
      aws_security_group.jumpserver-windows.id,
      module.bastion_linux.bastion_security_group
    ], local.lb_security_group_ids)
  }

  ingress {
    description = "Internal access to Weblogic Http"
    from_port   = "7777"
    to_port     = "7777"
    protocol    = "TCP"
    security_groups = concat([
      aws_security_group.jumpserver-windows.id,
      module.bastion_linux.bastion_security_group
    ], local.lb_security_group_ids)
  }

  ingress {
    description = "External access to prometheus node exporter"
    from_port   = "9100"
    to_port     = "9100"
    protocol    = "TCP"
    cidr_blocks = [module.ip_addresses.moj_cidr.aws_cloud_platform_vpc]
  }

  ingress {
    description = "External access to prometheus script exporter"
    from_port   = "9172"
    to_port     = "9172"
    protocol    = "TCP"
    cidr_blocks = [module.ip_addresses.moj_cidr.aws_cloud_platform_vpc]
  }

  egress {
    description = "Allow all egress"
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

