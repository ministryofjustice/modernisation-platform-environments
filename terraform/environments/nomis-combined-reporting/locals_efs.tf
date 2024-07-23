locals {

  efs = {
    sap_share = {
      access_points = {
        root = {
          posix_user = {
            gid = 1201 # binstall
            uid = 1201 # bobj
          }
          root_directory = {
            path = "/"
            creation_info = {
              owner_gid   = 1201 # binstall
              owner_uid   = 1201 # bobj
              permissions = "0777"
            }
          }
        }
      }
      file_system = {
        availability_zone_name = "eu-west-2a"
        lifecycle_policy = {
          transition_to_ia = "AFTER_30_DAYS"
        }
      }
      mount_targets = [{
        subnet_name        = "private"
        availability_zones = ["eu-west-2a"]
        security_groups    = ["bip"]
      }]
      tags = {
        backup = "false"
      }
    }
  }
}

