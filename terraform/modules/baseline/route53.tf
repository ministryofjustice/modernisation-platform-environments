locals {

  route53_resolver_security_group_rules = {
    dns-tcp = {
      type        = "egress"
      description = "Allow tcp/53 egress"
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    dns-udp = {
      type        = "egress"
      description = "Allow udp/53 egress"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  route53_resolver_rules_list = flatten([
    for resolver_key, resolver_value in var.route53_resolvers : [
      for rule_key, rule_value in resolver_value.forward : [{
        key = "${resolver_key}-${rule_key}"
        value = merge({
          resolver_name = resolver_key
          name          = replace(rule_key, ".", "-")
          domain_name   = rule_key
          rule_type     = "FORWARD"
        }, rule_value)
      }]
    ]
  ])

  route53_resolver_rules = { for item in local.route53_resolver_rules_list :
    item.key => item.value
  }
}

# create a single security group for all route53 resolvers.  Include the 
# application in the name since this is being created in the shared VPC account
resource "aws_security_group" "route53_resolver" {
  count = length(var.route53_resolvers) != 0 ? 1 : 0

  provider = aws.core-vpc

  name        = "${var.environment.application_name}-route53-resolver"
  description = "Route53 resolver security group for ${var.environment.application_name}"
  vpc_id      = var.environment.vpc.id

  tags = merge(local.tags, {
    Name = "${var.environment.application_name}-route53-resolver"
  })
}

resource "aws_security_group_rule" "route53_resolver" {
  for_each = length(var.route53_resolvers) != 0 ? local.route53_resolver_security_group_rules : {}

  provider = aws.core-vpc

  type              = each.value.type
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.route53_resolver[0].id
}

resource "aws_route53_resolver_endpoint" "this" {
  for_each = var.route53_resolvers

  provider = aws.core-vpc

  name      = each.key
  direction = each.value.direction

  security_group_ids = [aws_security_group.route53_resolver[0].id]

  dynamic "ip_address" {
    for_each = flatten([for subnet_name in each.value.subnet_names :
      var.environment.subnets[subnet_name].ids
    ])

    content {
      subnet_id = ip_address.value
    }
  }

  tags = merge(local.tags, {
    Name = each.key
  })
}

resource "aws_route53_resolver_rule" "this" {
  for_each = local.route53_resolver_rules

  provider = aws.core-vpc

  domain_name = each.value.domain_name
  name        = each.value.name
  rule_type   = each.value.rule_type

  resolver_endpoint_id = aws_route53_resolver_endpoint.this[each.value.resolver_name].id

  dynamic "target_ip" {
    for_each = each.value.target_ips
    content {
      ip = target_ip.value
    }
  }

  tags = merge(local.tags, {
    Name = each.value.name
  })
}

resource "aws_route53_resolver_rule_association" "this" {
  for_each = local.route53_resolver_rules

  provider = aws.core-vpc

  resolver_rule_id = aws_route53_resolver_rule.this[each.key].id
  vpc_id           = var.environment.vpc.id
}
