# locals {
#   target_group_arns = { for k, v in aws_lb_target_group.tribunals_target_group : k => v.arn }

#   # Create a mapping between listener headers and target group ARNs
#   listener_header_to_target_group = {
#     for k, v in var.services :
#     v.name_prefix => aws_lb_target_group.tribunals_target_group[k].arn
#   }
# }

# resource "aws_lb" "tribunals_lb" {
#   name                       = "tribunals-lb"
#   load_balancer_type         = "application"
#   security_groups            = [aws_security_group.tribunals_lb_sg_2.id]
#   subnets                    = data.aws_subnets.shared-public.ids
#   enable_deletion_protection = false
#   internal                   = false
# }

resource "aws_security_group" "tribunals_lb_sg_2" {
  name        = "tribunals-load-balancer-sg-2"
  description = "Control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Basic ingress rule for CloudFront
  ingress {
    description     = "Allow HTTPS from CloudFront"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# resource "aws_security_group" "tribunals_lb_sc" {
#   name        = "tribunals-load-balancer-sg"
#   description = "Control access to the load balancer"
#   vpc_id      = data.aws_vpc.shared.id

#   egress {
#     description = "Allow all outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_security_group_rule" "lb_cloudfront_ingress_https" {
#   type              = "ingress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
#   security_group_id = aws_security_group.tribunals_lb_sc.id
#   description       = "Allow HTTPS traffic from CloudFront"
# }

# resource "aws_security_group_rule" "lb_cloudfront_ingress_http" {
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
#   security_group_id = aws_security_group.tribunals_lb_sc.id
#   description       = "Allow HTTP traffic from CloudFront"
# }

# resource "aws_lb_target_group" "tribunals_target_group" {
#   for_each             = var.services
#   name                 = "${each.value.module_key}-tg"
#   port                 = each.value.port
#   protocol             = "HTTP"
#   vpc_id               = data.aws_vpc.shared.id
#   target_type          = "instance"
#   deregistration_delay = 30

#   stickiness {
#     type = "lb_cookie"
#   }

#   health_check {
#     healthy_threshold   = "3"
#     interval            = "15"
#     protocol            = "HTTP"
#     unhealthy_threshold = "3"
#     matcher             = "200-499"
#     timeout             = "10"
#   }
# }

data "aws_instances" "tribunals_instance" {
  filter {
    name   = "tag:Name"
    values = ["tribunals-instance"]
  }
}

# Make sure that the ec2 instance tagged as 'tribunals-instance' exists
# before adding aws_lb_target_group_attachment, otherwise terraform will fail
# resource "aws_lb_target_group_attachment" "tribunals_target_group_attachment" {
#   for_each         = aws_lb_target_group.tribunals_target_group
#   target_group_arn = each.value.arn
#   target_id        = element(data.aws_instances.tribunals_instance.ids, 0)
#   port             = each.value.port
# }

# resource "aws_lb_listener" "tribunals_lb" {
#   depends_on = [
#     aws_acm_certificate_validation.external
#   ]
#   certificate_arn   = aws_acm_certificate.external.arn
#   load_balancer_arn = aws_lb.tribunals_lb.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

#   default_action {
#     type = "fixed-response"
#     fixed_response {
#       content_type = "text/plain"
#       message_body = "No matching rule found"
#       status_code  = "404"
#     }
#   }
# }
# resource "aws_lb_listener_rule" "tribunals_lb_rule" {
#   for_each = local.listener_header_to_target_group

#   listener_arn = aws_lb_listener.tribunals_lb.arn
#   priority     = index(keys(local.listener_header_to_target_group), each.key) + 1

#   action {
#     type             = "forward"
#     target_group_arn = each.value
#   }

#   condition {
#     host_header {
#       values = ["*${each.key}.*"]
#     }
#   }
# }

# resource "aws_wafv2_web_acl_association" "web_acl_association_my_lb" {
#   resource_arn = aws_lb.tribunals_lb.arn
#   web_acl_arn  = aws_wafv2_web_acl.tribunals_web_acl.arn
# }

# resource "aws_cloudfront_distribution" "tribunals_distribution" {
#   origin {
#     domain_name = aws_lb.tribunals_lb.dns_name
#     origin_id   = "tribunalsLB"

#     custom_origin_config {
#       http_port              = 80
#       https_port             = 443
#       origin_protocol_policy = "https-only"
#       origin_ssl_protocols = ["TLSv1.2"]
#     }
#   }

#   default_cache_behavior {
#     target_origin_id = "tribunalsLB"

#     viewer_protocol_policy = "redirect-to-https"  // Redirect HTTP to HTTPS

#     allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
#     cached_methods = ["GET", "HEAD"]

#     forwarded_values {
#       query_string = false

#       cookies {
#         forward = "none"
#       }
#     }

#     min_ttl                = 0
#     default_ttl            = 86400
#     max_ttl                = 31536000
#   }

#   enabled             = true
#   is_ipv6_enabled     = true
#   comment             = "CloudFront distribution for tribunals load balancer"
#   price_class         = "PriceClass_All"

#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }
# }
