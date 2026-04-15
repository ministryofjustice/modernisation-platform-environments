##############################################
### WorkSpaces Type Profiles
###
### Defines the resource configuration for each
### workspace instance type. The instance_type
### field in new-workspace-users.tf maps to these.
##############################################

locals {
  workspace_types = {
    standard = {
      compute_type_name                         = "STANDARD"
      root_volume_size_gib                      = 80
      user_volume_size_gib                      = 50
      running_mode                              = "AUTO_STOP"
      running_mode_auto_stop_timeout_in_minutes = 60
    }
    performance = {
      compute_type_name                         = "PERFORMANCE"
      root_volume_size_gib                      = 100
      user_volume_size_gib                      = 100
      running_mode                              = "ALWAYS_ON"
      running_mode_auto_stop_timeout_in_minutes = null
    }
  }
}
