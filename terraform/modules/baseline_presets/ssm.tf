locals {

  # the modernisation platform secret 'environment_management' can not be
  # accessed from EC2s. Create a copy as an SSM parameter with just
  # the relevant account ids.
  account_names_for_account_ids_ssm_parameter = distinct(flatten([
    var.options.enable_ec2_oracle_enterprise_managed_server ? ["hmpps-oem-${var.environment.environment}"] : [],
    var.options.enable_ec2_oracle_enterprise_manager ? ["hmpps-oem-${var.environment.environment}"] : [],
  ]))

  # add a cloud watch windows SSM param if the file is present
  cloud_watch_windows_filename = "./templates/cloud_watch_windows.json"

  ssm_parameters_filter = flatten([
    length(local.account_names_for_account_ids_ssm_parameter) != 0 ? ["account"] : [],
    var.options.enable_ec2_user_keypair ? ["ec2-user"] : [],
    var.options.enable_ec2_cloud_watch_agent && fileexists(local.cloud_watch_windows_filename) ? ["cloud-watch-config"] : [],
  ])

  ssm_parameters = {

    account = {
      postfix = "_"
      parameters = {
        ids = {
          description = "Selected modernisation platform AWS account IDs"
          value = jsonencode({
            for key, value in var.environment.account_ids :
            key => value if contains(local.account_names_for_account_ids_ssm_parameter, key)
          })
        }
      }
    }

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

