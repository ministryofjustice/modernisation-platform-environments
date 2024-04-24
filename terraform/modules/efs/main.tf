resource "aws_efs_access_point" "this" {
  for_each = var.access_points

  file_system_id = aws_efs_file_system.this.id

  dynamic "posix_user" {
    for_each = each.value.posix_user != null ? [each.value.posix_user] : []
    content {
      gid = posix_user.value.gid
      uid = posix_user.value.uid
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

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}

resource "aws_efs_backup_policy" "this" {
  count = var.backup_policy_status != null ? 1 : 0

  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = var.backup_policy_status
  }
}

resource "aws_efs_file_system" "this" {
  availability_zone_name = var.file_system.availability_zone_name
  encrypted              = true
  kms_key_id             = var.file_system.kms_key_id
  performance_mode       = var.file_system.performance_mode

  dynamic "lifecycle_policy" {
    for_each = var.file_system.lifecycle_policy != null ? [var.file_system.lifecycle_policy] : []
    content {
      transition_to_ia                    = lifecycle_policy.value.transition_to_ia
      transition_to_primary_storage_class = lifecycle_policy.value.transition_to_primary_storage_class
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

data "aws_iam_policy_document" "this" {
  count = var.policy != null ? 1 : 0

  dynamic "statement" {
    for_each = var.policy
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
  count = var.policy != null ? 1 : 0

  file_system_id = aws_efs_file_system.this.id
  policy         = data.aws_iam_policy_document.this[0].json
}

resource "aws_efs_mount_target" "this" {
  for_each = var.mount_targets

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value.subnet_id
  security_groups = each.value.security_groups
}
