##############################################
### WorkSpaces Type Profiles
###
### Defines the workspace bundle and running mode
### for each instance type. The instance_type field
### in new-workspace-users.tf maps to these.
###
### Bundle specs (Windows Server 2025):
### - standard:    2 vCPU, 4 GB RAM, 80 GB root, 50 GB user
### - performance: 2 vCPU, 8 GB RAM, 80 GB root, 100 GB user
### - power:       4 vCPU, 16 GB RAM, 175 GB root, 100 GB user
##############################################

locals {
  workspace_types = {
    standard = {
      bundle_id                                 = "wsb-82dpmqfgh"  # Standard with Windows Server 2025
      running_mode                              = "AUTO_STOP"
      running_mode_auto_stop_timeout_in_minutes = 60
    }
    performance = {
      bundle_id                                 = "wsb-vz2zm0x4t"  # Performance with Windows Server 2025
      running_mode                              = "AUTO_STOP"
      running_mode_auto_stop_timeout_in_minutes = 60
    }
    power = {
      bundle_id                                 = "wsb-379lp03xq"  # Power with Windows Server 2025
      running_mode                              = "AUTO_STOP"
      running_mode_auto_stop_timeout_in_minutes = 60
    }
  }
}
