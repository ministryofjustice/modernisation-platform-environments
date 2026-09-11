#--NEED TO CONFIGURE ACCESS LOGS!!! - AW

#--Admin
resource "aws_lb" "admin" {
  name                       = "${local.component_name}-admin-lb"
  load_balancer_type         = "network"
  internal                   = true
  subnets                    = data.aws_subnets.shared-private.ids
  security_groups            = [aws_security_group.alb_admin.id]
  enable_deletion_protection = true

  access_logs {
    bucket  = module.s3-bucket-logging.bucket.id
    prefix  = local.lb_log_prefix_soa_admin
    enabled = true
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-admin", "${local.component_name}")) }
  )

  depends_on = [module.s3-bucket-logging]
}

# The following resouce is LB Target Group for Admin LB. It is used to route traffic to the Admin container.
resource "aws_lb_target_group" "admin_https" {
  name                 = "ccms-soa-sandbox-admin-test-tg"
  port                 = 443
  protocol             = "TLS"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    interval            = 30
    path                = "/weblogic/ready"
    port                = local.application_data.accounts[local.environment].admin_ssl_port
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
  # THe following lifecycle block is used to ensure that the target group is created before the listener is created.
  # This is to avoid the error "Error creating LB Listener:
  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_lb_listener" "admin443" {
#   load_balancer_arn = aws_lb.admin.id
#   port              = 443
#   protocol          = "TLS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = aws_acm_certificate_validation.soa-sandbox.certificate_arn
#   default_action {
#     target_group_arn = aws_lb_target_group.admin_https.id
#     type             = "forward"
#   }
# }

resource "aws_lb_listener" "admin_ssl_port" {
  load_balancer_arn = aws_lb.admin.id
  port              = local.application_data.accounts[local.environment].admin_ssl_port
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.soa-sandbox.certificate_arn
  default_action {
    target_group_arn = aws_lb_target_group.admin_https.id
    type             = "forward"
  }
}

#Temporary purpose for testing. It should be removed once the testing is done. 
resource "aws_lb_listener" "admin80" {
  load_balancer_arn = aws_lb.admin.id
  port              = 80 #--Don't know why HTTP is being listened, is this a redirect? Why? - Revist. AW
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.admin.id
    type             = "forward"
  }
}


#--Managed
resource "aws_lb" "managed" {
  name                       = "${local.component_name}-managed-api-lb"
  load_balancer_type         = "network"
  internal                   = true
  subnets                    = data.aws_subnets.shared-private.ids
  security_groups            = [aws_security_group.alb_managed.id]
  enable_deletion_protection = true

  access_logs {
    bucket  = module.s3-bucket-logging.bucket.id
    prefix  = local.lb_log_prefix_soa_managed
    enabled = true
  }

  tags = merge(local.tags,
    { Name = lower(format("lb-%s-managed", "${local.component_name}")) }
  )

  depends_on = [module.s3-bucket-logging]
}

# The following resouce is LB Target Group for Managed LB. It is used to route traffic to the Managed container.
resource "aws_lb_target_group" "managed_https" {
  name                 = "ccms-soa-sandbox-mgd-https-tg"
  port                 = 443
  protocol             = "TLS"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    interval            = 30
    path                = "/weblogic/ready"
    port                = local.application_data.accounts[local.environment].admin_ssl_port
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
   # THe following lifecycle block is used to ensure that the target group is created before the listener is created.
  # This is to avoid the error "Error creating LB Listener:
  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_lb_listener" "managed443" {
#   load_balancer_arn = aws_lb.managed.id
#   port              = 443
#   protocol          = "TLS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = aws_acm_certificate_validation.soa-sandbox.certificate_arn
#   default_action {
#     target_group_arn = aws_lb_target_group.managed_https.id
#     type             = "forward"
#   }
# }

resource "aws_lb_listener" "managed_ssl_port" {
  load_balancer_arn = aws_lb.managed.id
  port              = local.application_data.accounts[local.environment].managed_ssl_port
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.soa-sandbox.certificate_arn
  default_action {
    target_group_arn = aws_lb_target_group.managed_https.id
    type             = "forward"
  }
}

#Temporary purpose for testing. It should be removed once the testing is done.
resource "aws_lb_listener" "managed80" {
  load_balancer_arn = aws_lb.managed.id
  port              = 80 #--Don't know why HTTP is being listened, is this a redirect? Why? - Revist. AW
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.managed.id
    type             = "forward"
  }
}