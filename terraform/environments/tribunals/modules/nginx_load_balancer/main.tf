terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

# tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "nginx_lb" {
  #checkov:skip=CKV_AWS_91:"Access logging not required for this load balancer"
  #checkov:skip=CKV_AWS_150:"Deletion protection not needed in this environment"
  #checkov:skip=CKV2_AWS_20:"HTTP to HTTPS redirection is handled at the listener level"
  #tfsec:ignore:AVD-AWS-0053
  #checkov:skip=CKV2_AWS_28:"WAF protection is handled at CloudFront level"
  name                       = "tribunals-nginx"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.nginx_lb_sg_id]
  subnets                    = var.subnets_shared_public_ids
  enable_deletion_protection = false
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "nginx_lb_tg" {
  #checkov:skip=CKV_AWS_378: Allow HTTP protocol for transport
  #checkov:skip=CKV_AWS_261:"Health check properly configured with matcher for redirect"
  name     = "tribunals-nginx"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_shared_id
  health_check {
    matcher = "301"
  }
}

output "nginx_lb_arn" {
  value = aws_lb.nginx_lb.dns_name
}

output "nginx_lb_zone_id" {
  value = aws_lb.nginx_lb.zone_id
}

variable "nginx_instance_ids" {
  type = map(string)
}

variable "nginx_lb_sg_id" {
  type = string
}

variable "subnets_shared_public_ids" {
  type        = list(string)
  description = "Public subnets"
}

variable "vpc_shared_id" {
  type = string
}

variable "external_acm_cert_arn" {
  type = string
}

resource "aws_lb_target_group_attachment" "nginx_lb_tg_attachment" {
  for_each = var.nginx_instance_ids

  target_group_arn = aws_lb_target_group.nginx_lb_tg.arn
  target_id        = each.value
  port             = 80
}

#trivy:ignore:AVD-AWS-0054:"HTTP listener is required for HTTP to HTTPS redirection"
resource "aws_lb_listener" "nginx_lb_listener" {
  #checkov:skip=CKV_AWS_2:"HTTP listener is required for HTTP to HTTPS redirection"
  #checkov:skip=CKV_AWS_103:"TLS version check not applicable for HTTP listener"
  load_balancer_arn = aws_lb.nginx_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_lb_tg.arn
  }
}

resource "aws_lb_listener" "nginx_lb_listener_https" {
  certificate_arn   = var.external_acm_cert_arn
  load_balancer_arn = aws_lb.nginx_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_lb_tg.arn
  }
}
