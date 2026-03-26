##############################################
### WorkSpaces Directory with IAM Identity Center
###
### ⚠️ MANUAL CREATION + IMPORT REQUIRED
###
### STEP 1: Create directory manually in AWS Console with IAM Identity Center
### STEP 2: Add the directory ID to application_variables.json: workspaces_directory_id
### STEP 3: Import into Terraform:
###   terraform import aws_workspaces_directory.workspaces[0] d-xxxxxxxxxx
### STEP 4: Apply to manage the configuration
###
### This resource will only be created when workspaces_directory_id is set in application_variables.json
##############################################

resource "aws_workspaces_directory" "workspaces" {
  count = (
    local.environment == "development" &&
    try(local.application_data.accounts[local.environment].workspaces_directory_id, "") != ""
  ) ? 1 : 0

  # This directory_id comes from application_variables.json after manual creation
  directory_id = local.application_data.accounts[local.environment].workspaces_directory_id
  subnet_ids   = try(data.terraform_remote_state.workspace_components.outputs.private_subnet_ids, [])

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
      "AuthenticationType" = "IAM-Identity-Center"
      "IdentityProvider"   = "IAMIdentityCenter"
      "DirectoryType"      = "IAMIdentityCenter"
    }
  )

  lifecycle {
    # Prevent replacement if directory_id is updated after import
    ignore_changes = [directory_id]
  }
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
### WorkSpaces Creation
##############################################
# resource "aws_workspaces_workspace" "workspaces" {
#   for_each = local.environment == "development" ? local.workspace_users : {}
#
#   directory_id = aws_workspaces_directory.workspaces[0].id
#   bundle_id    = local.application_data.accounts[local.environment].workspace_bundle_id
#   user_name    = each.value.email  # Use IAM Identity Center username (usually email)
#
#   root_volume_encryption_enabled = true
#   user_volume_encryption_enabled = true
#   volume_encryption_key          = data.aws_kms_key.ebs_shared.arn
#
#   workspace_properties {
#     compute_type_name                         = local.workspace_types[each.value.instance_type].compute_type_name
#     root_volume_size_gib                      = local.workspace_types[each.value.instance_type].root_volume_size_gib
#     user_volume_size_gib                      = local.workspace_types[each.value.instance_type].user_volume_size_gib
#     running_mode                              = local.workspace_types[each.value.instance_type].running_mode
#     running_mode_auto_stop_timeout_in_minutes = local.workspace_types[each.value.instance_type].running_mode_auto_stop_timeout_in_minutes
#   }
#
#   tags = merge(
#     local.tags,
#     {
#       "Name"              = "${local.application_name}-${local.environment}-workspace-${each.key}"
#       "User"              = each.key
#       "Email"             = each.value.email
#       "AuthSource"        = "IAMIdentityCenter"
#       "IAMIdentityCenter" = local.application_data.accounts[local.environment].identity_center_instance_arn
#     }
#   )
# }
# }

