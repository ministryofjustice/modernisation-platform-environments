locals {
    loadbalancer_ingress_rules = {
        "lb_ingress" = {
        description     = "Loadbalancer ingress rule from CloudFront"
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
        }
    }
}

resource "aws_cloudfront_distribution" "tribunals_distribution" {
  origin {
    domain_name = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
    origin_id   = "tribunalsOrigin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2", "TLSv1.1"]
      origin_keepalive_timeout = 60
      origin_read_timeout     = 60
    }

    custom_header {
      name  = "X-Custom-Header"
      value = "tribunals-origin"
    }
  }

  default_cache_behavior {
    target_origin_id = "tribunalsOrigin"

    forwarded_values {
      query_string = false
      headers      = ["Host"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods       = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods        = ["GET", "HEAD"]

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront distribution for tribunals load balancer"
  price_class     = "PriceClass_All"

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "tribunals_lb_sg_cloudfront" {
  name        = "tribunals-load-balancer-sg-cf"
  description = "control access to the load balancer using cloudfront"
  vpc_id      = data.aws_vpc.shared.id

  dynamic "ingress" {
    for_each = local.loadbalancer_ingress_rules
    content {
      description     = lookup(ingress.value, "description", null)
      from_port       = lookup(ingress.value, "from_port", null)
      to_port         = lookup(ingress.value, "to_port", null)
      protocol        = lookup(ingress.value, "protocol", null)
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
      prefix_list_ids = lookup(ingress.value, "prefix_list_ids", null)
    }
  }

  egress {
    description = "allow all outbound traffic from the load balancer - needed due to dynamic port mapping on ec2 instance"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
