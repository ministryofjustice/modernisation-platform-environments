#------------------------------------------------------------------------------
# Security Group
#------------------------------------------------------------------------------

# The security group will be common across all weblogic instances so it is
# defined outside of this module. (it is envisaged that they will be accessed
# from a single jumpserver.  Also it makes it easier to manage the loadbalancer
# egress rules if there is a single security group.)

#------------------------------------------------------------------------------
# EC2
#------------------------------------------------------------------------------

# user-data template
data "template_file" "user_data" {
  template = file("${path.module}/user-data/user-data.sh")
  vars = {
    ENV                     = var.name
    DB_HOSTNAME             = "db.${var.name}.${var.application_name}.${data.aws_route53_zone.internal.name}"
    USE_DEFAULT_CREDS       = var.use_default_creds
    AUTO_SCALING_GROUP_NAME = local.auto_scaling_group_name
    LIFECYCLE_HOOK_NAME     = local.initial_lifecycle_hook_name
    REGION                  = var.region
  }
}

data "aws_vpc" "shared_vpc" {
  tags = {
    Name = "${var.business_unit}-${var.environment}"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared_vpc.id]
  }
  tags = {
    Name = "${var.business_unit}-${var.environment}-${var.subnet_set}-private-${var.region}*"
  }
}

resource "aws_launch_template" "weblogic" {
  name = var.name

  dynamic "block_device_mappings" {
    for_each = data.aws_ami.weblogic.block_device_mappings
    iterator = device
    content {
      device_name = device.value.device_name
      ebs {
        delete_on_termination = true
        encrypted             = true
        volume_size           = device.value.ebs.volume_size
        volume_type           = "gp3"
      }
    }
  }

  disable_api_termination = var.termination_protection
  ebs_optimized           = local.ebs_optimized

  iam_instance_profile {
    arn = aws_iam_instance_profile.weblogic.arn
  }

  image_id                             = data.aws_ami.weblogic.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.instance_type
  key_name                             = var.key_name

  # metadata_options { # http_endpoint/http_tokens forces instance to use IMDSv2 which is incompatible with Weblogic
  #   http_endpoint = "enabled"
  #   http_tokens   = "required"
  # }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.common_security_group_id]
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      {
        Name       = "weblogic-${var.name}"
        component  = "application"
        os_type    = "Linux"
        os_version = "RHEL 6.10"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      var.tags,
      {
        Name = "weblogic-${var.name}"
      }
    )
  }

  user_data = base64encode(data.template_file.user_data.rendered)

  tags = merge(
    var.tags,
    {
      Name = "weblogic-${var.name}-launch-template"
    }
  )

}

#------------------------------------------------------------------------------
# Auto Scaling Group
#------------------------------------------------------------------------------
resource "aws_autoscaling_group" "weblogic" {
  launch_template {
    id      = aws_launch_template.weblogic.id
    version = aws_launch_template.weblogic.latest_version
  }

  initial_lifecycle_hook {
    # this hook is triggered in the user-data script once weblogic script has completed
    name                 = local.initial_lifecycle_hook_name
    default_result       = "ABANDON"
    heartbeat_timeout    = 3000 # inital weblogic setup takes about 45 mins!
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90 # seems that instances in the warm pool are included in the % health count so this needs to be set fairly high
      instance_warmup        = 3000
    }
  }

  desired_capacity          = var.asg_desired_capacity
  name                      = local.auto_scaling_group_name
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  termination_policies      = ["OldestInstance"]
  target_group_arns         = [aws_lb_target_group.weblogic.arn]
  vpc_zone_identifier       = data.aws_subnets.private.ids
  wait_for_capacity_timeout = 0

  warm_pool {
    pool_state                  = "Stopped"
    min_size                    = var.asg_warm_pool_min_size
    max_group_prepared_capacity = var.asg_max_size
  }

  tag {
    key                 = "Name"
    value               = "weblogic-${var.name}"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_schedule" "scale_down" {
  scheduled_action_name  = "weblogic_scale_down"
  min_size               = 0
  max_size               = var.asg_max_size # this should make sure instances move to warm pool rather than being deleted
  desired_capacity       = 0
  recurrence             = "0 19 * * *"
  autoscaling_group_name = aws_autoscaling_group.weblogic.name
}

resource "aws_autoscaling_schedule" "scale_up" {
  scheduled_action_name  = "weblogic_scale_up"
  min_size               = var.asg_min_size
  max_size               = var.asg_max_size
  desired_capacity       = var.asg_desired_capacity
  recurrence             = "0 7 * * *"
  autoscaling_group_name = aws_autoscaling_group.weblogic.name
}

#------------------------------------------------------------------------------
# Loadbalancer rules
#------------------------------------------------------------------------------
resource "aws_lb_target_group" "weblogic" {

  name_prefix          = "weblc-"
  port                 = "7777" # port on which targets receive traffic
  protocol             = "HTTP"
  target_type          = "instance"
  deregistration_delay = "30"
  vpc_id               = data.aws_vpc.shared_vpc.id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled             = true
    interval            = "30"
    healthy_threshold   = "3"
    matcher             = "200-399"
    path                = "/keepalive.htm"
    port                = "7777"
    timeout             = "5"
    unhealthy_threshold = "5"
  }

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  tags = merge(
    var.tags,
    {
      Name = "weblogic-${var.name}-tg"
    },
  )
}

resource "aws_lb_listener_rule" "weblogic" {
  listener_arn = var.load_balancer_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.weblogic.arn
  }
  condition {
    host_header {
      values = ["${var.name}.${var.application_name}.${data.aws_route53_zone.external.name}"]
    }
  }
}

#------------------------------------------------------------------------------
# Instance profile to be assumed by the ec2 instances
#------------------------------------------------------------------------------
resource "aws_iam_role" "weblogic" {
  name                 = "ec2-weblogic-role-${var.name}"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )

  inline_policy {
    name   = "weblogic-policy"
    policy = data.aws_iam_policy_document.weblogic.json
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    var.instance_profile_policy_arn
  ]

  tags = merge(
    var.tags,
    {
      Name = "ec2-weblogic-role-${var.name}"
    },
  )
}

resource "aws_iam_instance_profile" "weblogic" {
  name = "ec2-weblogic-profile-${var.name}"
  role = aws_iam_role.weblogic.name
  path = "/"
}

data "aws_iam_policy_document" "weblogic" {
  statement {
    sid     = "ParameterAccessForWeblogicSetup"
    effect  = "Allow"
    actions = ["ssm:GetParameter"]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.id}:parameter/weblogic/default/*",
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.id}:parameter/weblogic/${var.name}/*"
    ]
  }

  statement {
    sid     = "TriggerInstanceLifecycleHooks"
    effect  = "Allow"
    actions = ["autoscaling:CompleteLifecycleAction"]
    resources = [
      "arn:aws:autoscaling:${var.region}:${data.aws_caller_identity.current.id}:autoScalingGroup:*:autoScalingGroupName/${local.auto_scaling_group_name}"
    ]
  }
}