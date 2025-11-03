# # Public ALB for WebGate
# resource "aws_lb" "webgate_public_lb" {
#   name               = lower(format("public-alb-webgate"))
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.sg_webgate_lb.id]
#   subnets            = data.aws_subnets.shared-public.ids

#   drop_invalid_header_fields = true
#   enable_deletion_protection = false

#   access_logs {
#     bucket  = module.s3-bucket-logging.bucket.id
#     prefix  = local.lb_log_prefix_wgate_public
#     enabled = true
#   }

#   tags = merge(local.tags,
#     { Name = lower(format("public-alb-webgate")) }
#   )
# }

# resource "aws_lb_listener" "webgate_public_listener" {
#   count = local.is-production ? 1 : 1

#   load_balancer_arn = aws_lb.webgate_public_lb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   certificate_arn   = data.aws_acm_certificate.gandi_cert.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.webgate_tg_public.id
#   }
# }

# resource "aws_lb_target_group" "webgate_tg_public" {
#   name     = lower(format("public-alb-webgate-tg"))
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

# resource "aws_lb_target_group_attachment" "webgate_public" {
#   count            = local.application_data.accounts[local.environment].webgate_no_instances
#   target_group_arn = aws_lb_target_group.webgate_tg_public.arn
#   target_id        = element(aws_instance.ec2_webgate.*.id, count.index)
#   port             = 5401
# }

# resource "aws_wafv2_web_acl_association" "webgate_waf_association" {
#   resource_arn = aws_lb.webgate_public_lb.arn
#   web_acl_arn  = aws_wafv2_web_acl.ebs_web_acl.arn
# }