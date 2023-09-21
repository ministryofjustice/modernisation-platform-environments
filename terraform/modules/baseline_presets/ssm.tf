locals {

  # add a cloud watch windows SSM param if the file is present
  cloud_watch_windows_filename = "./templates/cloud_watch_windows.json"

  ssm_parameters_filter = flatten([
    var.options.enable_ec2_user_keypair ? ["ec2-user"] : [],
    var.options.enable_ec2_cloud_watch_agent && fileexists(local.cloud_watch_windows_filename) ? ["cloud-watch-config"] : [],
  ])

  ssm_parameters = {

    cloud-watch-config = {
      postfix = "-"
      parameters = {
        windows = {
          description = "cloud watch agent config for windows"
          file        = local.cloud_watch_windows_filename
          type        = "String"
        }
      }
    }

    ec2-user = {
      postfix = "_"
      parameters = {
        pem = {
          description = "Private key for ec2-user key pair"
        }
      }
    }

  }
}

