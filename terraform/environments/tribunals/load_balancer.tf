locals {
  target_group_arns = { for k, v in aws_lb_target_group.tribunals_target_group : k => v.arn }

  # Create a mapping between listener headers and target group ARNs
  listener_header_to_target_group = {
    for k, v in var.services :
    v.name_prefix => aws_lb_target_group.tribunals_target_group[k].arn
  }
}

resource "aws_lb" "tribunals_lb" {
  name                       = "tribunals-lb"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.tribunals_lb_sg_cloudfront.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  internal                   = false

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "alb-logs"
    enabled = true
  }
}

resource "aws_security_group" "tribunals_lb_sc" {
  name        = "tribunals-load-balancer-sg"
  description = "control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  # ingress {
  #   description = "allow all traffic on HTTPS port 443"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # ingress {
  #   description = "allow all traffic on HTTP port 80"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    description = "allow all outbound traffic from the load balancer - needed due to dynamic port mapping on ec2 instance"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "tribunals_target_group" {
  for_each             = var.services
  name                 = "${each.value.module_key}-tg"
  port                 = each.value.port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    healthy_threshold   = "3"
    interval            = "15"
    protocol            = "HTTP"
    unhealthy_threshold = "3"
    matcher             = "200-499"
    timeout             = "10"
  }
}

data "aws_instances" "tribunals_instance" {
  filter {
    name   = "tag:Name"
    values = ["tribunals-instance"]
  }
}

# Make sure that the ec2 instance tagged as 'tribunals-instance' exists
# before adding aws_lb_target_group_attachment, otherwise terraform will fail
resource "aws_lb_target_group_attachment" "tribunals_target_group_attachment" {
  for_each         = aws_lb_target_group.tribunals_target_group
  target_group_arn = each.value.arn
  target_id        = element(data.aws_instances.tribunals_instance.ids, 0)
  port             = each.value.port
}

resource "aws_lb_listener" "tribunals_lb" {
  depends_on = [
    aws_acm_certificate_validation.external
  ]
  certificate_arn   = aws_acm_certificate.external.arn
  load_balancer_arn = aws_lb.tribunals_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No matching rule found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "tribunals_lb_rule" {
  for_each = local.listener_header_to_target_group

  listener_arn = aws_lb_listener.tribunals_lb.arn
  priority     = index(keys(local.listener_header_to_target_group), each.key) + 1

  action {
    type             = "forward"
    target_group_arn = each.value
  }

  condition {
    host_header {
      values = ["*${each.key}.*"]
    }
  }
}

resource "aws_lb_listener_rule" "cloudfront_check" {
  listener_arn = aws_lb_listener.tribunals_lb.arn
  priority     = 0

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied"
      status_code  = "403"
    }
  }

  condition {
    http_header {
      http_header_name = "X-Custom-Header"
      values           = ["tribunals-origin"]
    }
  }
}

# resource "aws_wafv2_web_acl_association" "web_acl_association_my_lb" {
#   resource_arn = aws_lb.tribunals_lb.arn
#   web_acl_arn  = aws_wafv2_web_acl.tribunals_web_acl.arn
# }

## Create S3 Bucket for Load Balancer logging ##

resource "aws_s3_bucket" "lb_logs" {
  bucket = "tribunals-lb-logs-${local.environment}"
}

resource "aws_s3_bucket_versioning" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.lb_logs.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.lb_logs.arn}/*"
        ]
      }
    ]
  })
}

# Get the AWS account ID for the ALB service account
data "aws_elb_service_account" "main" {}