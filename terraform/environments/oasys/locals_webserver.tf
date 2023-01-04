locals {
  webserver = { # env independent webserver vars

    # server-type and nomis-environment auto set by module
    tags = {
      description = "oasys webserver"
      component   = "web"
      server-type = "webserver"
    }

    instance = {
      disable_api_termination      = false
      instance_type                = "t2.large"
      key_name                     = aws_key_pair.ec2-user.key_name
      monitoring                   = true
      metadata_options_http_tokens = "optional"
      vpc_security_group_ids       = [aws_security_group.webserver.id]
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

    ssm_parameters_prefix = "webserver/"
    iam_resource_names_prefix = "ec2-webserver-asg"

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







