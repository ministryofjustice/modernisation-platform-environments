resource "aws_codedeploy_app" "this" {
  for_each         = { for pair in var.services : join("", keys(pair)) => pair }
  name             = each.key
  compute_platform = "ECS"
}

data "aws_lb" "internal" {
  name = var.internal_alb_name
}

data "aws_lb_listener" "internal" {
  load_balancer_arn = data.aws_lb.internal.arn
  port              = var.internal_listener_port
}

data "aws_lb" "external" {
  name = var.external_alb_name
}

data "aws_lb_listener" "external" {
  load_balancer_arn = data.aws_lb.external.arn
  port              = var.external_listener_port
}


data "aws_lb_target_group" "one" {
  for_each = { for pair in var.services : join("", keys(pair)) => pair }

  name = "${each.key}-target-group-1"
}

data "aws_lb_target_group" "two" {
  for_each = { for pair in var.services : join("", keys(pair)) => pair }
  name     = "${each.key}-target-group-2"
}

#create codedeploy service iam role
resource "aws_iam_role" "codedeploy_service_role" {
  name = "codedeploy-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com",
        },
        Action = "sts:AssumeRole",
      },
    ],
  })
}

#attach AWSCodeDeployRoleForECS policy
resource "aws_iam_policy_attachment" "codedeploy_service_role_policy" {
  name       = "AWSCodeDeployRoleForECS"
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  roles      = [aws_iam_role.codedeploy_service_role.name]
}

resource "aws_codedeploy_deployment_group" "this" {
  for_each               = { for pair in var.services : join("", keys(pair)) => pair }
  deployment_group_name  = each.key
  app_name               = aws_codedeploy_app.this[each.key].name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy_service_role.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 0
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  ecs_service {
    cluster_name = var.cluster_name
    service_name = each.key
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = each.value[join("", keys(each.value))] == "external" ? [data.aws_lb_listener.external.arn, data.aws_lb_listener.internal.arn] : [data.aws_lb_listener.internal.arn]
      }

      target_group {
        name = data.aws_lb_target_group.one[each.key].name
      }

      target_group {
        name = data.aws_lb_target_group.two[each.key].name
      }
    }
  }
  depends_on = [aws_iam_policy_attachment.codedeploy_service_role_policy]
}
