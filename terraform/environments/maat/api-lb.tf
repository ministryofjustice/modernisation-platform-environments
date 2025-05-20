# ######################################
# # Load Balancer Resources
# ######################################
# resource "aws_lb" "maat_api_ecs_lb" {
#   name               = "${local.application_name}-api-ecs-lb"
#   load_balancer_type = "application"
#   subnets            = [data.aws_subnets.shared-private.ids[0], data.aws_subnets.shared-private.ids[1], data.aws_subnets.shared-private.ids[2], ]
#   security_groups    = [aws_security_group.maat_api_alb_sg.id]
#   idle_timeout       = 65

#   tags = {
#     Name = "${local.application_name}-api-ecs-lb"
#   }

#   enable_deletion_protection = false
# }

# resource "aws_lb_target_group" "maat_api_ecs_target_group" {
#   name                 = "${local.application_name}-api-ecs-target-group"
#   port                 = 8090
#   protocol             = "HTTP"
#   vpc_id               = data.aws_vpc.shared.id
#   deregistration_delay = 30
#   target_type          = "ip"
#   depends_on           = [aws_lb.maat_api_ecs_lb]

#   health_check {
#     path                = "/actuator"
#     protocol            = "HTTP"
#     port                = 8090
#     interval            = 15
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 3
#   }

#   stickiness {
#     enabled = false
#     type    = "lb_cookie"
#   }
# }

# resource "aws_lb_listener" "maat_api_alb_http_listener" {
#   load_balancer_arn = aws_lb.maat_api_ecs_lb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.maat_api_ecs_target_group.arn
#   }
# }

# resource "aws_lb_listener_rule" "maat_api_ecs_alb_http_listener_rule" {
#   listener_arn = aws_lb_listener.maat_api_alb_http_listener.arn
#   priority     = 1

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.maat_api_ecs_target_group.arn
#   }

#   condition {
#     path_pattern {
#       values = ["/"]
#     }
#   }
# }