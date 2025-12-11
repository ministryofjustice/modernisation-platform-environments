resource "aws_security_group" "boe_efs" {
  #checkov:skip=CKV2_AWS_5 "ignore"
  name_prefix = "${var.env_name}-boe-efs"
  vpc_id      = var.account_info.vpc_id
}

resource "aws_security_group_rule" "boe_efs_ingress" {
  for_each = {
    nfs-from-bcs = { protocol = "tcp", port = 2049, source_security_group_id = aws_security_group.bcs.id }
    nfs-from-bps = { protocol = "tcp", port = 2049, source_security_group_id = aws_security_group.bps.id }
  }

  description              = each.key
  protocol                 = lookup(each.value, "protocol", "-1")
  from_port                = lookup(each.value, "port", lookup(each.value, "from_port", 0))
  to_port                  = lookup(each.value, "port", lookup(each.value, "to_port", 0))
  self                     = lookup(each.value, "self", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)

  security_group_id = resource.aws_security_group.boe_efs.id
  type              = "ingress"
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
      security_groups = [aws_security_group.boe_efs.id]
    }
  }

  tags = merge(var.tags, {
    backup = "true"
  })
}
