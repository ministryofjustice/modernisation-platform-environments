##############################################
### WorkSpaces Directory with IAM Identity Center
###
### This resource was manually created in the AWS Console
### and should be imported using:
### terraform import aws_workspaces_directory.workspaces_identity_center d-9c674d0524
###
### IMPORTANT: This is an imported resource. The directory
### was created outside Terraform with Identity Center
### as the identity provider.
##############################################

resource "aws_workspaces_directory" "workspaces_identity_center" {
  count = local.environment == "development" ? 1 : 0

  directory_id = "d-9c674d0524"
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

  ip_group_ids = [aws_workspaces_ip_group.workspaces_identity_center[0].id]

  depends_on = [
    aws_iam_role_policy_attachment.workspaces_default_service_access,
    aws_iam_role_policy_attachment.workspaces_default_self_service_access,
  ]

  tags = merge(
    local.tags,
    {
      "Name"               = "${local.application_name}-${local.environment}-workspaces-directory-ic"
      "AuthenticationType" = "IdentityCenter"
      "IdentityProvider"   = "IAM_Identity_Center"
      "DirectoryType"      = "IdentityCenter"
    }
  )
}

##############################################
### WorkSpaces IP Group for Identity Center
##############################################

resource "aws_workspaces_ip_group" "workspaces_identity_center" {
  count = local.environment == "development" ? 1 : 0

  name        = "${local.application_name}-${local.environment}-ip-group-ic"
  description = "IP access control group for Identity Center WorkSpaces"

  rules {
    source      = "0.0.0.0/0"
    description = "Allow all - refine based on requirements"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ip-group-ic" }
  )
}

##############################################
### WorkSpaces for Identity Center Users
###
### These WorkSpaces use IAM Identity Center
### for authentication instead of Active Directory
##############################################

resource "aws_workspaces_workspace" "workspaces_identity_center" {
  for_each = local.environment == "development" ? local.workspace_users : {}

  directory_id = aws_workspaces_directory.workspaces_identity_center[0].id
  bundle_id    = local.application_data.accounts[local.environment].workspace_bundle_id
  user_name    = each.value.email  # For Identity Center, use email as username

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
      "Name"           = "${local.application_name}-${local.environment}-workspace-${each.key}"
      "User"           = each.key
      "Email"          = each.value.email
      "InstanceType"   = each.value.instance_type
      "IdentityCenter" = "true"
    }
  )

  depends_on = [
    aws_workspaces_directory.workspaces_identity_center
  ]
}

##############################################
### Outputs
##############################################

output "workspaces_identity_center_directory_id" {
  description = "WorkSpaces Directory ID for Identity Center"
  value       = local.environment == "development" ? aws_workspaces_directory.workspaces_identity_center[0].id : null
}

output "workspaces_identity_center_registration_code" {
  description = "Registration code for WorkSpaces client"
  value       = local.environment == "development" ? aws_workspaces_directory.workspaces_identity_center[0].registration_code : null
}

output "workspaces_identity_center_workspace_ids" {
  description = "Map of username to WorkSpace ID"
  value = local.environment == "development" ? {
    for k, v in aws_workspaces_workspace.workspaces_identity_center : k => v.id
  } : {}
}
