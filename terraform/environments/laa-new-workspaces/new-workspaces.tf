##############################################
### WorkSpaces Directory with Microsoft AD
###
### This resource registers the AWS Managed Microsoft AD
### with WorkSpaces to enable workspace provisioning.
##############################################

resource "aws_workspaces_directory" "workspaces_ad" {

  directory_id = aws_directory_service_directory.workspaces_ad.id
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

  ip_group_ids = [aws_workspaces_ip_group.workspaces.id]

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

  name        = "${local.application_name}-${local.environment}-ip-group"
  description = "IP access control group"

  rules {
    source      = "35.176.93.186/32"
    description = "Global Protect Gateway"
  }
  rules {
    source      = "18.130.148.126/32"
    description = "Global Protect 3rd Gateway"
  }
  rules {
    source      = "35.176.148.126/32"
    description = "Global Protect 4th Gateway"
  }
  rules {
    source      = "18.169.147.172/32"
    description = "Global Protect 2nd Gateway"
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-ip-group" }
  )
}
