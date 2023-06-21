locals {
  efs = {
    ohs = {
      sec_group_id = aws_security_group.ohs_instance.id

    },
    oam = {
      sec_group_id = aws_security_group.oam_instance.id

    },
    oim = {
      sec_group_id = aws_security_group.ohs_instance.id

    },
    idm = {
      sec_group_id = aws_security_group.idm_instance.id

    }

  }
}

resource "aws_efs_file_system" "product" {
  for_each = {
    for k, v in local.efs : k => v
  }
  encrypted   = true
  performance_mode    = "generalPurpose"
  throughput_mode = "elastic"


  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${each.key}-product" },
    local.environment != "production" ? { "snapshot-with-daily-35-day-retention" = "yes" } : { "snapshot-with-hourly-35-day-retention" = "yes" }
  )
}

resource "aws_efs_mount_target" "product_a" {
  for_each = {
    for k, v in local.efs : k => v
  }
  file_system_id  = aws_efs_file_system.product[each.key].id
  subnet_id       = data.aws_subnet.private_subnets_a.id
  security_groups = [aws_security_group.efs_product[each.key].id]
}

resource "aws_efs_mount_target" "product_b" {
  for_each = {
    for k, v in local.efs : k => v
  }
  file_system_id  = aws_efs_file_system.product[each.key].id
  subnet_id       = data.aws_subnet.private_subnets_b.id
  security_groups = [aws_security_group.efs_product[each.key].id]
}

resource "aws_efs_mount_target" "product_c" {
  for_each = {
    for k, v in local.efs : k => v
  }
  file_system_id  = aws_efs_file_system.product[each.key].id
  subnet_id       = data.aws_subnet.private_subnets_c.id
  security_groups = [aws_security_group.efs_product[each.key].id]
}

resource "aws_security_group" "efs_product" {
  for_each = {
    for k, v in local.efs : k => v
  }
  name        = "${local.application_name}-${local.environment}-${each.key}-efs-security-group"
  description = "Portal ${upper(each.key)} Product EFS Security Group"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_egress_rule" "efs_product_outbound" {
  for_each = {
    for k, v in local.efs : k => v
  }
  security_group_id = aws_security_group.efs_product[each.key].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "efs_product_inbound" {
  for_each = {
    for k, v in local.efs : k => v
  }
  security_group_id            = aws_security_group.efs_product[each.key].id
  description                  = "EFS Rule inbound for ${upper(each.key)} instance"
  referenced_security_group_id = each.value.sec_group_id
  from_port                    = 2049
  ip_protocol                  = "tcp"
  to_port                      = 2049
}
