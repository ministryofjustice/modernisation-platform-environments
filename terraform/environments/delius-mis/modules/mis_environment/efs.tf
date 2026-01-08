resource "aws_security_group" "efs" {
  #checkov:skip=CKV2_AWS_5 "ignore"
  name        = "${var.app_name}-${var.env_name}-boe-efs-sg"
  description = "Security group for EFS"
  vpc_id      = var.account_info.vpc_id

  tags = merge(var.tags, {
    Name = "${var.app_name}-${var.env_name}-boe-efs-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "efs" {
  for_each = {
    nfs-from-bcs = { ip_protocol = "TCP", port = 2049, referenced_security_group_id = aws_security_group.bcs_ec2.id }
    nfs-from-bps = { ip_protocol = "TCP", port = 2049, referenced_security_group_id = aws_security_group.bps_ec2.id }
  }

  description       = each.key
  security_group_id = resource.aws_security_group.efs.id

  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  ip_protocol                  = lookup(each.value, "ip_protocol", "-1")
  from_port                    = lookup(each.value, "port", lookup(each.value, "from_port", null))
  to_port                      = lookup(each.value, "port", lookup(each.value, "to_port", null))
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "efs" {
  for_each = {
  }

  description       = each.key
  security_group_id = resource.aws_security_group.efs.id

  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  ip_protocol                  = lookup(each.value, "ip_protocol", "-1")
  from_port                    = lookup(each.value, "port", lookup(each.value, "from_port", null))
  to_port                      = lookup(each.value, "port", lookup(each.value, "to_port", null))
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)

  tags = var.tags
}

module "boe_efs" {
  source = "../../../../modules/efs"

  count = var.boe_efs_config != null ? 1 : 0

  name = "${var.app_name}-${var.env_name}-boe-efs"

  access_points = {
    root = {
      posix_user = {
        gid = 1201 # binstall
        uid = 1201 # bobj
      }
      root_directory = {
        path = "/"
        creation_info = {
          owner_gid   = 1201 # binstall
          owner_uid   = 1201 # bobj
          permissions = "0777"
        }
      }
    }
  }

  file_system = {
    availability_zone_name = var.boe_efs_config.availability_zone_name
    kms_key_id             = var.account_config.kms_keys["general_shared"]
    lifecycle_policy = {
      transition_to_ia = "AFTER_30_DAYS"
    }
  }

  mount_targets = {
    for key, value in var.boe_efs_config.mount_targets_subnet_ids : key => {
      subnet_id       = value
      security_groups = [aws_security_group.efs.id]
    }
  }

  tags = merge(var.tags, {
    backup = "true"
  })
}
