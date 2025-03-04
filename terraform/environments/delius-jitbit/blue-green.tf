locals {
    # just used to test for now, will use the default listener rule when properly implemented
    blue_green_url  = "${var.networking[0].application}-blue-green.${var.networking[0].business-unit}-${local.environment}.${local.domain}"
}


# used to check which is being used
resource "aws_ssm_parameter" "blue_green" {
  name        = "/blue_green"
  type        = "String"
  value       = "blue"
  description = "used to check which is being used"

  lifecycle {
    ignore_changes  = [value]
  }
}

data "aws_ssm_parameter" "blue_green" {
  name = aws_ssm_parameter.blue_green.name
}



module "ecs_blue" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v2.0.1"

  environment = local.environment
  name        = "${local.application_name}-blue"

  tags = local.tags
}

module "ecs_green" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v2.0.1"

  environment = local.environment
  name        = "${local.application_name}-green"

  tags = local.tags
}

resource "aws_lb_target_group" "target_group_blue" {

  name                 = "${local.application_name}-blue"
  port                 = local.app_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path                = "/User/Login?ReturnUrl=%2f"
    healthy_threshold   = "5"
    interval            = "120"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_lb_target_group" "target_group_green" {

  name                 = "${local.application_name}-green"
  port                 = local.app_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path                = "/User/Login?ReturnUrl=%2f"
    healthy_threshold   = "5"
    interval            = "120"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_lb_listener_rule" "blue_green" {
  count        = local.is-development ? 1 : 0
  listener_arn = aws_lb_listener.listener.arn
  priority     = 20

  action {
    target_group_arn = data.aws_ssm_parameter.blue_green.value == "blue" ? aws_lb_target_group.target_group_blue.arn : aws_lb_target_group.target_group_green.arn
    type             = "forward"
  }

  condition {
    host_header {
      values = [local.blue_green_url]
    }
  }
}