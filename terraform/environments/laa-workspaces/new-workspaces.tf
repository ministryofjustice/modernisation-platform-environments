##############################################
### WorkSpaces Directory with Microsoft AD
###
### This resource registers the AWS Managed Microsoft AD
### with WorkSpaces to enable workspace provisioning.
##############################################

resource "aws_workspaces_directory" "workspaces_ad" {
  count = local.environment == "development" ? 1 : 0

  directory_id = aws_directory_service_directory.workspaces_ad[0].id
  subnet_ids   = data.terraform_remote_state.workspace_components.outputs.private_subnet_ids

  self_service_permissions {
    change_compute_type  = false
    increase_volume_size = false
    rebuild_workspace    = true
    restart_workspace    = true
    switch_running_mode  = false
  }

  workspace_access_properties {
    device_type_android    = "DENY"
    device_type_chromeos   = "DENY"
    device_type_ios        = "DENY"
    device_type_linux      = "DENY"
    device_type_osx        = "ALLOW"
    device_type_web        = "ALLOW"
    device_type_windows    = "ALLOW"
    device_type_zeroclient = "DENY"
  }

  workspace_creation_properties {
    enable_internet_access              = false
    enable_maintenance_mode             = true
    user_enabled_as_local_administrator = false
  }

  ip_group_ids = [aws_workspaces_ip_group.workspaces[0].id]

  depends_on = [
    aws_iam_role_policy_attachment.workspaces_default_service_access,
    aws_iam_role_policy_attachment.workspaces_default_self_service_access,
    aws_iam_role_policy.workspaces_ds_access,
  ]

  tags = merge(
    local.tags,
    {
      "Name"               = "${local.application_name}-${local.environment}-workspaces-directory"
      "AuthenticationType" = "ActiveDirectory"
      "IdentityProvider"   = "MicrosoftAD"
      "DirectoryType"      = "MicrosoftAD"
    }
  )
}

##############################################
### WorkSpaces IP Group (Access Control)
##############################################

resource "aws_workspaces_ip_group" "workspaces" {
  count = local.environment == "development" ? 1 : 0

  name        = "${local.application_name}-${local.environment}-ip-group"
  description = "IP access control group"

  rules {
    source      = "0.0.0.0/0"
    description = "Allow all"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ip-group" }
  )
}

##############################################
### WorkSpaces Creation with Microsoft AD
###
### Automatically creates WorkSpaces for users
### defined in new-workspace-users.tf
##############################################

resource "aws_workspaces_workspace" "workspaces_ad" {
  for_each = local.environment == "development" ? local.workspace_users : {}

  directory_id = aws_workspaces_directory.workspaces_ad[0].id
  bundle_id    = local.application_data.accounts[local.environment].workspace_bundle_id
  user_name    = each.key # AD username (sam-account-name)

  root_volume_encryption_enabled = true
  user_volume_encryption_enabled = true
  volume_encryption_key          = aws_kms_key.ebs[0].arn

  workspace_properties {
    compute_type_name                         = local.workspace_types[each.value.instance_type].compute_type_name
    root_volume_size_gib                      = local.workspace_types[each.value.instance_type].root_volume_size_gib
    user_volume_size_gib                      = local.workspace_types[each.value.instance_type].user_volume_size_gib
    running_mode                              = local.workspace_types[each.value.instance_type].running_mode
    running_mode_auto_stop_timeout_in_minutes = local.workspace_types[each.value.instance_type].running_mode_auto_stop_timeout_in_minutes
  }

  tags = merge(
    local.tags,
    {
      "Name"       = "${local.application_name}-${local.environment}-workspace-${each.key}"
      "User"       = each.key
      "Email"      = each.value.email
      "AuthSource" = "MicrosoftAD"
    }
  )

  depends_on = [
    terraform_data.ad_users,
    aws_workspaces_directory.workspaces_ad
  ]
}
