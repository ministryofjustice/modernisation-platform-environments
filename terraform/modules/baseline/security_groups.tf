locals {

  # The security group rules variable matches the inline syntax for rules, see
  # aws_security_group terraform documentation.  We create individual rules here
  # for more flexibility, e.g. so we can define dependencies between security
  # groups, and additional rules can be added elsewhere.
  # Unfortunately, the individual aws_security_group_rule doesn't allow combined
  # self/cidr/security_groups to we split them out here.

  # flatten security group rules
  security_group_rule_list = [[
    for sg_key, sg_value in var.security_groups : [
      for rule_key, rule_value in sg_value.ingress : {
        key = "${sg_key}-ingress-${rule_key}"
        value = merge(rule_value, {
          type                = "ingress"
          security_group_name = sg_key
        })
      }
    ]], [
    for sg_key, sg_value in var.security_groups : [
      for rule_key, rule_value in sg_value.egress : {
        key = "${sg_key}-egress-${rule_key}"
        value = merge(rule_value, {
          type                = "egress"
          security_group_name = sg_key
        })
      }
    ]
  ]]
  security_group_rule_list_self = [
    for item in flatten(local.security_group_rule_list) : {
      key = "${item.key}-self"
      value = merge(item.value, {
        cidr_blocks              = null
        source_security_group_id = null
      })
    } if item.value.self != null
  ]
  security_group_rule_list_cidrs = [
    for item in flatten(local.security_group_rule_list) : {
      key = "${item.key}-cidrs"
      value = merge(item.value, {
        self                     = null
        source_security_group_id = null
      })
    } if item.value.cidr_blocks != null
  ]
  security_group_rule_list_sgs = [
    for item in flatten(local.security_group_rule_list) : [
      for security_group in item.value.security_groups != null ? item.value.security_groups : [] : {
        key = "${item.key}-${security_group}"
        value = merge(item.value, {
          self                     = null
          cidr_blocks              = null
          source_security_group_id = security_group
        })
      } if item.value.security_groups != null
    ]
  ]
  security_group_rule_list_others = [
    for item in flatten(local.security_group_rule_list) : {
      key = item.key
      value = merge(item.value, {
        source_security_group_id = null
      })
    } if item.value.self == null && item.value.cidr_blocks == null && item.value.security_groups == null
  ]
  security_group_rules = { for item in flatten([
    local.security_group_rule_list_self,
    local.security_group_rule_list_cidrs,
    local.security_group_rule_list_sgs,
    local.security_group_rule_list_others]) : item.key => item.value
  }

  # get map of security group ids that can be referenced by the rules
  security_group_ids_bastion = length(module.bastion_linux) == 1 ? {
    bastion-linux = module.bastion_linux[0].bastion_security_group
  } : {}
  security_group_ids = merge(local.security_group_ids_bastion, {
    for key, value in aws_security_group.this : key => value.id
  })
}

resource "aws_security_group" "this" {
  for_each = var.security_groups

  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource" since they are attached elsewhere

  name        = each.key
  description = each.value.description
  vpc_id      = var.environment.vpc.id

  tags = merge(local.tags, each.value.tags, {
    Name = each.key
  })
}

resource "aws_security_group_rule" "this" {
  for_each = local.security_group_rules

  type                     = each.value.type
  description              = each.value.description
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id == null ? null : lookup(local.security_group_ids, each.value.source_security_group_id, each.value.source_security_group_id)
  self                     = each.value.self
  prefix_list_ids          = each.value.prefix_list_ids
  security_group_id        = resource.aws_security_group.this[each.value.security_group_name].id
}
