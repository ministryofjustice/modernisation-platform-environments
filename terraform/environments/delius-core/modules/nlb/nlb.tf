resource "aws_lb" "ldap" {
  name                       = local.ldap_nlb_name
  internal                   = var.internal
  load_balancer_type         = var.load_balancer_type
  subnets                    = var.account_config.private_subnet_ids
  drop_invalid_header_fields = var.drop_invalid_header_fields
  enable_deletion_protection = var.enable_deletion_protection

  tags = local.ldap_nlb_tags
}

resource "aws_lb_listener" "ldap" {
  load_balancer_arn = aws_lb.ldap.arn
  port              = local.ldap_port
  protocol          = local.ldap_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ldap.arn
  }

  tags = local.ldap_nlb_tags
}

resource "aws_lb_target_group" "ldap" {
  name     = local.ldap_name
  port     = local.ldap_port
  protocol = local.ldap_protocol
  vpc_id   = var.account_info.vpc_id

  target_type          = "ip"
  deregistration_delay = "30"
  tags = merge(
    var.tags,
    {
      Name = local.ldap_name
    }
  )
}

# Internal DNS name for LDAP load balancer - Internal LDAP consumers will use this
resource "aws_route53_record" "ldap_dns_internal" {
  provider = aws.core-vpc
  zone_id  = var.account_config.route53_inner_zone_info.zone_id
  name     = "${var.env_name}.ldap.${var.account_info.application_name}"
  type     = "A"

  alias {
    name                   = aws_lb.ldap.dns_name
    zone_id                = aws_lb.ldap.zone_id
    evaluate_target_health = true # Could be true or false based on https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-values-alias.html#rrsets-values-alias-evaluate-target-health
  }
}
