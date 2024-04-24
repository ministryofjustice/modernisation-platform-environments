locals {
  efs_mount_targets_list = flatten([
    for efs_key, efs_value in var.elastic_file_systems : [
      for mount_key, mount_value in efs_value.mount_targets : [
        for az in mount_value.availability_zones : {
          key = "${efs_key}-${mount_key}-${az}"
          value = merge(mount_value, {
            efs_key           = efs_key
            subnet_name       = mount_key
            availability_zone = az
          })
        }
      ]
    ]
  ])
  efs_mount_targets = { for item in local.efs_mount_targets_list : item.key => item.value }

  efs_access_points_list = flatten([
    for efs_key, efs_value in var.elastic_file_systems : [
      for access_key, access_value in efs_value.access_points : {
        key = "${efs_key}-${access_key}"
        value = merge(access_value, {
          efs_key = efs_key
          efs     = efs_value
        })
      }
    ]
  ])
  efs_access_points = { for item in local.efs_access_points_list : item.key => item.value }
}

resource "aws_efs_file_system" "this" {
  for_each = var.elastic_file_systems

  availability_zone_name = each.value.availability_zone_name
  encrypted              = true
  kms_key_id             = each.value.kms_key_id != null ? try(var.environment.kms_keys[each.value.kms_key_id].arn, each.value.kms_key_id) : null
  performance_mode       = each.value.performance_mode

  dynamic "lifecycle_policy" {
    for_each = each.value.lifecycle_policy != null ? [each.value.lifecycle_policy] : []
    content {
      transition_to_ia                    = lifecycle_policy.value.transition_to_ia
      transition_to_primary_storage_class = lifecycle_policy.value.transition_to_primary_storage_class
    }
  }

  tags = merge(local.tags, each.value.tags, {
    Name = each.key
  })
}

resource "aws_efs_access_point" "this" {
  for_each = local.efs_access_points

  file_system_id = aws_efs_file_system.this[each.value.efs_key].id

  dynamic "posix_user" {
    for_each = each.value.posix_user != null ? [each.value.posix_user] : []
    content {
      gid            = posix_user.value.gid
      uid            = posix_user.value.uid
      secondary_gids = posix_user.value.secondary_gids
    }
  }

  dynamic "root_directory" {
    for_each = each.value.root_directory != null ? [each.value.root_directory] : []
    content {
      path = root_directory.value.path
      dynamic "creation_info" {
        for_each = root_directory.value.creation_info != null ? [root_directory.value.creation_info] : []
        content {
          owner_gid   = creation_info.value.owner_gid
          owner_uid   = creation_info.value.owner_uid
          permissions = creation_info.value.permissions
        }
      }
    }
  }

  tags = merge(local.tags, each.value.efs.tags, {
    Name = each.key
  })
}

resource "aws_efs_backup_policy" "this" {
  for_each = { for key, value in var.elastic_file_systems : key => value if value.backup_policy != null }

  file_system_id = aws_efs_file_system.this[each.key].id

  backup_policy {
    status = each.value.backup_policy
  }
}

data "aws_iam_policy_document" "efs" {
  for_each = { for key, value in var.elastic_file_systems : key => value if value.policy != null }

  dynamic "statement" {
    for_each = each.value.policy
    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
      dynamic "principals" {
        for_each = statement.value.principals != null ? [statement.value.principals] : []
        content {
          type        = principals.value.type
          identifiers = [for identifier in principals.value.identifiers : try(var.environment.account_root_arns[identifier], identifier)]
        }
      }
      dynamic "condition" {
        for_each = statement.value.conditions
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_efs_file_system_policy" "this" {
  for_each = { for key, value in var.elastic_file_systems : key => value if value.policy != null }

  file_system_id = aws_efs_file_system.this[each.key].id
  policy         = data.aws_iam_policy_document.efs[each.key].json
}

resource "aws_efs_mount_target" "this" {
  for_each = local.efs_mount_targets

  file_system_id  = aws_efs_file_system.this[each.value.efs_key].id
  subnet_id       = var.environment.subnet[each.value.subnet_name][each.value.availability_zone].id
  security_groups = [for sg in each.value.security_groups : try(aws_security_group.this[sg].id, null)]
}


