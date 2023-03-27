locals {
  route53_security_groups = length(var.route53_resolvers) != 0 ? {
    route53-resolver = {
      description = "Security group for Route53 resolver"
      ingress     = {}
      egress = {
        dns-tcp = {
          description = "Allow tcp/53 egress"
          from_port   = 53
          to_port     = 53
          protocol    = "tcp"
          cidr_blocks = [var.environment.vpc.cidr_block]
        }
        dns-udp = {
          description = "Allow udp/53 egress"
          from_port   = 53
          to_port     = 53
          protocol    = "udp"
          cidr_blocks = [var.environment.vpc.cidr_block]
        }
      }
      tags = {}
    }
  } : {}

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

resource "aws_route53_resolver_endpoint" "this" {
  for_each = var.route53_resolvers

  provider = aws.core-vpc

  name      = each.key
  direction = each.value.direction

  security_group_ids = [aws_security_group.this["route53-resolver"].id]

  dynamic "ip_address" {
    for_each = flatten([for subnet_name in each.value.subnet_names :
      var.environment.subnets[subnet_name].ids
    ])

    content {
      subnet_id = ip_address.value
    }
  }

  # No tags as member-delegation roles don't currently have route53resolver:TagResource permission
  # tags = merge(local.tags, {
  #   Name = each.key
  # })
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
