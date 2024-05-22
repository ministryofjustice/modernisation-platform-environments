locals {
  # lookup subnet ids and lookup security group ids for mount targets
  efs_mount_targets_list = {
    for efs_key, efs_value in var.efs : efs_key => flatten([
      for mount_target in efs_value.mount_targets : [
        for az in mount_target.availability_zones : {
          key = "${mount_target.subnet_name}-${az}"
          value = {
            subnet_id       = var.environment.subnet[mount_target.subnet_name][az].id
            security_groups = [for sg in mount_target.security_groups : try(aws_security_group.this[sg].id, sg)]
          }
        }
      ]
    ])
  }

  efs_mount_targets = {
    for efs_key, efs_value in local.efs_mount_targets_list : efs_key => {
      for item in efs_value : item.key => item.value
    }
  }
}

module "efs" {
  for_each = var.efs

  source = "../../modules/efs"

  access_points = each.value.access_points
  file_system = merge(each.value.file_system, {
    kms_key_id = try(var.environment.kms_keys[each.value.file_system.kms_key_id].arn, each.value.file_system.kms_key_id)
  })
  mount_targets = local.efs_mount_targets[each.key]
  name          = each.key
  policy        = each.value.policy
  tags          = merge(local.tags, each.value.tags)
}

