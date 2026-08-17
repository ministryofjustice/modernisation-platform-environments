# resource "aws_lb" "frontend_internal" {
#   name               = "frontend-internal-alb"
#   internal           = true
#   load_balancer_type = "application"

#   security_groups = [
#     aws_security_group.alb_internal_sg.id
#   ]

#   subnets = local.account_config.private_subnet_ids

#   enable_deletion_protection = false
#   idle_timeout               = 60

#   tags = local.tags
# }

# resource "aws_lb_listener" "frontend_internal_http" {
#   load_balancer_arn = aws_lb.frontend_internal.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.frontend_internal.arn
#   }
# }

# resource "aws_lb_target_group" "frontend_internal" {
#   name     = "vcms-frontend-internal"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = local.account_info.vpc_id

#   health_check {
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#     timeout             = 5
#     interval            = 30
#     path                = "/"
#     matcher             = "200-399"
#   }
# }

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.frontend_internal.arn
#   port              = 443
#   protocol          = "HTTPS"

#   ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   certificate_arn = aws_acm_certificate.internal.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.frontend_internal.arn
#   }

#   tags = local.tags
# }
