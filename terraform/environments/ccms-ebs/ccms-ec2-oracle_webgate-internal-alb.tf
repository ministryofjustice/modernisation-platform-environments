# resource "aws_lb" "webgate_lb" {
#   count              = local.is-production ? 1 : 1
#   name               = lower(format("lb-%s-%s-wgate", local.application_name, local.environment))
#   internal           = true
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.sg_webgate_lb.id]
#   subnets            = data.aws_subnets.shared-private.ids

#   drop_invalid_header_fields = true
#   enable_deletion_protection = false

#   access_logs {
#     bucket  = module.s3-bucket-logging.bucket.id
#     prefix  = local.lb_log_prefix_wgate
#     enabled = true
#   }

#   tags = merge(local.tags,
#     { Name = lower(format("lb-%s-%s-wgate", local.application_name, local.environment)) }
#   )
# }

# resource "aws_lb_target_group" "webgate_internal_tg" {
#   name     = lower(format("tg-%s-wgate", local.application_name))
#   port     = 5401
#   protocol = "HTTP"
#   vpc_id   = data.aws_vpc.shared.id
#   health_check {
#     port     = 5401
#     protocol = "HTTP"
#     matcher  = 302
#     timeout  = 10
#   }
# }

# resource "aws_lb_listener" "webgate__internal_listener" {
#   depends_on = [
#     aws_acm_certificate_validation.external
#   ]

#   load_balancer_arn = aws_lb.webgate_alb_internal.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   certificate_arn   = local.cert_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.webgate_internal_tg.id
#   }
# }

# resource "aws_lb_target_group_attachment" "webgate_internal" {
#   count            = local.application_data.accounts[local.environment].webgate_no_instances
#   target_group_arn = aws_lb_target_group.webgate_internal_tg.arn
#   target_id        = element(aws_instance.ec2_webgate.*.id, count.index)
#   port             = 5401
# }