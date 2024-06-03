resource "aws_lb" "this" {
  name                       = "${var.app_name}-${var.env_name}-nlb"
  internal                   = var.internal
  load_balancer_type         = var.load_balancer_type
  subnets                    = var.subnet_ids
  drop_invalid_header_fields = var.drop_invalid_header_fields
  enable_deletion_protection = var.enable_deletion_protection



  tags = var.tags
}

resource "aws_lb_listener" "ldap" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.port
  protocol          = var.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = merge(
    var.tags,
    {
      Name = var.app_name
    }
  )
}

resource "aws_lb_listener" "ldaps" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.secure_port
  protocol          = "TLS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  certificate_arn = var.certificate_arn

  tags = merge(
    var.tags,
    {
      Name = var.app_name
    }
  )
}

resource "aws_lb_target_group" "this" {
  name     = "${var.app_name}-${var.env_name}"
  port     = var.port
  protocol = var.protocol
  vpc_id   = var.vpc_id

  preserve_client_ip = "true"

  target_health_state {
    enable_unhealthy_connection_termination = true
  }

  connection_termination = true

  deregistration_delay = var.deregistration_delay

  target_type = "ip"

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    port                = "traffic-port"
    protocol            = "TCP"
  }

  tags = merge(
    var.tags,
    {
      Name = var.app_name
    }
  )
}

# Internal DNS name for LDAP load balancer - Internal LDAP consumers will use this
resource "aws_route53_record" "ldap_dns_internal" {
  provider = aws.core-vpc
  zone_id  = var.zone_id
  name     = "${var.app_name}.${var.env_name}.${var.mp_application_name}"
  type     = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true # Could be true or false based on https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-values-alias.html#rrsets-values-alias-evaluate-target-health
  }
}
