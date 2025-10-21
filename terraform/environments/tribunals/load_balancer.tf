locals {
  target_group_arns = { for k, v in aws_lb_target_group.tribunals_target_group : k => v.arn }

  # Create a mapping between listener headers and target group ARNs
  listener_header_to_target_group = {
    for k, v in var.services : v.name_prefix => (
      aws_lb_target_group.tribunals_target_group[k].arn
    )
  }
  service_priorities = {
    # Priority 1 was ommitted from the listener rules to allow the maintenance page to take precedence (when it's needed)
    adminappeals             = 2
    administrativeappeals    = 3
    carestandards            = 4
    charity                  = 5
    cicap                    = 6
    claimsmanagement         = 7
    consumercreditappeals    = 8
    employmentappeals        = 9
    estateagentappeals       = 10
    financeandtax            = 11
    immigrationservices      = 12
    informationrights        = 13
    landregistrationdivision = 14
    landschamber             = 15
    phl                      = 16
    siac                     = 17
    tax                      = 19
    taxandchancery_ut        = 20
    transportappeals         = 21
    asylumsupport            = 22
  }
}

# tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "tribunals_lb" {
  #checkov:skip=CKV_AWS_91:"Access logging not required for this load balancer"
  #checkov:skip=CKV2_AWS_28:"WAF protection is handled at CloudFront level"
  #tfsec:ignore:AVD-AWS-0053
  name                       = "tribunals-lb"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.tribunals_lb_sc.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = true
  internal                   = false
  drop_invalid_header_fields = true
}

resource "aws_security_group" "tribunals_lb_sc" {
  #checkov:skip=CKV_AWS_260:"Public access required for web application"
  #checkov:skip=CKV_AWS_382:"Full egress access required for dynamic port mapping"
  name        = "tribunals-load-balancer-sg"
  description = "control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow all traffic on HTTPS port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow all traffic on HTTP port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound traffic from the load balancer - needed due to dynamic port mapping on ec2 instance"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "tribunals_target_group" {
  #checkov:skip=CKV_AWS_261:"Health check is properly configured with path and matcher"
  for_each = var.services
  name     = "${each.value.module_key}-tg"
  #checkov:skip=CKV_AWS_378: Allow HTTP protocol for transport
  port                 = each.value.port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    healthy_threshold = "3"
    interval          = "15"
    #checkov:skip=CKV_AWS_378: Allow HTTP protocol for transport
    protocol            = "HTTP"
    unhealthy_threshold = "3"
    matcher             = "200-499"
    timeout             = "10"
    path                = "/"
  }
}

data "aws_instances" "primary_instance" {
  filter {
    name   = "tag:Role"
    values = ["Primary"]
  }

  depends_on = [aws_autoscaling_group.tribunals-all-asg]
}

data "aws_instances" "backup_instance" {
  filter {
    name   = "tag:Role"
    values = ["Backup"]
  }

  depends_on = [aws_autoscaling_group.tribunals-all-asg]
}

# Make sure that the ec2 instance tagged as 'tribunals-instance' exists
# before adding aws_lb_target_group_attachment, otherwise terraform will fail
resource "aws_lb_target_group_attachment" "tribunals_target_group_attachment" {
  for_each         = aws_lb_target_group.tribunals_target_group
  target_group_arn = each.value.arn
  # target_id points to primary ec2 instance, change "primary_instance" to "backup_instance" in order to point at backup ec2 instance
  target_id = data.aws_instances.primary_instance.ids[0]
  port      = each.value.port

  depends_on = [data.aws_instances.primary_instance]
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
  priority     = local.service_priorities[each.key]
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

# Maintenance page - uncomment whenever a maintenance page is needed
# resource "aws_lb_listener_rule" "maintenance_page" {
#   listener_arn = aws_lb_listener.tribunals_lb.arn
#   priority     = 1

# action {
#     type = "fixed-response"
#     fixed_response {
#       content_type = "text/html"
#       message_body = <<EOF
# <!DOCTYPE html>
# <html lang="en">
# <head>
#     <meta charset="UTF-8">
#     <meta name="viewport" content="width=device-width, initial-scale=1.0">
#     <title>Maintenance - We'll be back soon</title>
# </head>
# <body style="font-family:Arial,sans-serif;text-align:center;padding:40px;max-width:600px;margin:0 auto">
#     <div style="background:#fff;padding:20px;border-radius:10px">
#         <div style="font-size:48px">🔧</div>
#         <h1>We'll be back soon!</h1>
#         <p>We are currently performing scheduled maintenance to improve our services. We apologize for any inconvenience.</p>
#         <p>Please check back shortly. Thank you for your patience.</p>
#     </div>
# </body>
# </html>
# EOF
#       status_code  = "503"
#     }
#   }

#   condition {
#     host_header {
#       values = ["*.*"]
#     }
#   }
# }
