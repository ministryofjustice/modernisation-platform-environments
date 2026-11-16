resource "aws_security_group" "schema_generation" {
  for_each = local.generation_sources

  name        = "${local.generation_function_prefix}-${each.key}"
  description = "Network access for schema generation source ${each.key}."
  vpc_id      = each.value.vpc_id

  tags = merge(local.tags, {
    Name = "${local.generation_function_prefix}-${each.key}"
  })
}

resource "aws_vpc_security_group_egress_rule" "generation_database" {
  for_each = local.generation_sources

  security_group_id = aws_security_group.schema_generation[each.key].id

  referenced_security_group_id = each.value.database_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = each.value.database_port
  to_port                      = each.value.database_port

  description = "Connect to the configured source database."
}

resource "aws_vpc_security_group_egress_rule" "generation_https" {
  for_each = local.generation_sources

  security_group_id = aws_security_group.schema_generation[each.key].id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "Access AWS APIs through the existing platform network."
}

resource "aws_vpc_security_group_ingress_rule" "database_from_generation" {
  for_each = local.generation_sources

  security_group_id = each.value.database_security_group_id

  referenced_security_group_id = aws_security_group.schema_generation[each.key].id
  ip_protocol                  = "tcp"
  from_port                    = each.value.database_port
  to_port                      = each.value.database_port

  description = "Allow schema generation to read source database metadata."
}
