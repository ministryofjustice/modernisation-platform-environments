resource "aws_datasync_location_efs" "destination" {
  count = var.ldap_config.efs_datasync_destination_arn != null ? 1 : 0
  ec2_config {
    security_group_arns = [aws_security_group.ldap_efs.arn]
    subnet_arn          = "arn:aws:ec2:${var.account_info.region}:${var.account_info.id}:subnet/${var.account_config.private_subnet_ids[0]}"
  }
  efs_file_system_arn = var.ldap_config.efs_datasync_destination_arn
}

resource "aws_datasync_location_efs" "source" {
  ec2_config {
    security_group_arns = [aws_security_group.ldap_efs.arn]
    subnet_arn          = "arn:aws:ec2:${var.account_info.region}:${var.account_info.id}:subnet/${var.account_config.private_subnet_ids[0]}"
  }
  efs_file_system_arn = aws_efs_file_system.ldap.arn
}

resource "aws_datasync_task" "ldap_refresh_task" {
  count                    = var.ldap_config.efs_datasync_destination_arn != null ? 1 : 0
  destination_location_arn = aws_datasync_location_efs.destination[0].arn
  source_location_arn      = aws_datasync_location_efs.source.arn

  name = "ldap-datasync-task-push-from-${var.env_name}"
}

# iam role for aws backup to assume in the data-refresh pipeline using the aws backup start-restore-job cmd
resource "aws_iam_role" "ldap_datasync_role" {
  name               = "ldap-data-refresh-role-${var.env_name}"
  assume_role_policy = data.aws_iam_policy_document.ldap_datasync_role_assume.json
}

resource "aws_iam_role_policy" "ldap_refresh_access" {
  policy = data.aws_iam_policy_document.ldap_datasync_role_access.json
  role   = aws_iam_role.ldap_datasync_role.name
}

data "aws_iam_policy_document" "ldap_datasync_role_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com", "backup.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ldap_datasync_role_access" {
  statement {
    effect = "Allow"
    actions = [
      "backup:*",
      "datasync:*",
      "elasticfilesystem:*",
    ]
    resources = ["*"]
  }
  statement {
    sid     = "allowAccessForDataSync"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "${module.s3_bucket_ldap_data_refresh.bucket.arn}",
      "${module.s3_bucket_ldap_data_refresh.bucket.arn}/*",
    ]
  }
}

locals {
  delius_core_accounts = { for k, v in nonsensitive(var.platform_vars.environment_management.account_ids) : k => v if startswith(k, "delius-core") }
  ldap_refresh_bucket_policies = [for account_name, account_id in local.delius_core_accounts :
    {
      effect  = "Allow"
      actions = ["s3:*"]
      resources = [
        "${module.s3_bucket_ldap_data_refresh.bucket.arn}",
        "${module.s3_bucket_ldap_data_refresh.bucket.arn}/*",
      ]
      principals = {
        type        = "AWS"
        identifiers = ["*"]
      }
      condition = {
        test     = "ArnLike"
        values   = ["arn:aws:iam::${account_id}:role/ldap-data-refresh-role-*"]
        variable = "aws:PrincipalARN"
      }
    }
  ]

}


module "s3_bucket_ldap_data_refresh" {
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"
  bucket_name         = "${var.env_name}-ldap-data-refresh-incoming"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  custom_kms_key      = var.account_config.general_shared_kms_key_arn
  bucket_policy_v2    = local.ldap_refresh_bucket_policies

  providers = {
    aws.bucket-replication = aws.bucket-replication
  }

  tags = local.tags
}
#
#data "aws_iam_policy_document" "datasync_s3_ldap_refresh_access" {
#  for_each = { for k, v in nonsensitive(var.platform_vars.environment_management.account_ids) : k => v if startswith(k, "delius-core") }
#  statement {
#    sid     = "allowAccessForDataSync_${each.key}"
#    effect  = "Allow"
#    actions = ["s3:*"]
#    resources = [
#      "${module.s3_bucket_ldap_data_refresh.bucket.arn}",
#      "${module.s3_bucket_ldap_data_refresh.bucket.arn}/*",
#    ]
#    principals {
#      type        = "AWS"
#      identifiers = ["*"]
#    }
#    condition {
#      test     = "ArnLike"
#      values   = ["arn:aws:iam::${each.value}:role/ldap-data-refresh-role-*"]
#      variable = "aws:PrincipalARN"
#    }
#  }
#}
