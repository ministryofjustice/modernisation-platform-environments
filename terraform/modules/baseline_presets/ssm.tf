locals {

  # the modernisation platform secret 'environment_management' can not be
  # accessed from EC2s. Create a copy as an SSM parameter with just
  # the relevant account ids.
  account_names_for_account_ids_ssm_parameter = distinct(flatten([
    var.options.enable_ec2_delius_dba_secrets_access ? ["delius-core-${var.environment.environment}"] : [],
    var.options.enable_ec2_oracle_enterprise_managed_server ? ["hmpps-oem-${var.environment.environment}"] : [],
    var.options.enable_hmpps_domain && contains(["development", "test"], var.environment.environment) ? ["hmpps-domain-services-test"] : [],
    var.options.enable_hmpps_domain && contains(["preproduction", "production"], var.environment.environment) ? ["hmpps-domain-services-production"] : [],
  ]))

  # add a cloud watch windows SSM param if the file is present
  cloud_watch_windows_filename = "./templates/cloud_watch_windows.json"

  ssm_documents_filter = flatten([
    var.options.enable_hmpps_domain ? ["ec2-ad-join-windows"] : [],
    var.options.enable_hmpps_domain ? ["ec2-ad-leave-windows"] : [],
  ])

  ssm_documents = {
    for item in fileset("${path.module}/ssm-documents", "*.yaml") :
    trimsuffix(item, ".yaml") => {
      document_type   = "Command"
      document_format = "YAML"
      content         = file("${path.module}/ssm-documents/${item}")
    }
  }

  ssm_parameters_filter = flatten([
    length(local.account_names_for_account_ids_ssm_parameter) != 0 ? ["account"] : [],
    var.options.enable_azure_sas_token ? ["/azure"] : [],
    var.options.enable_ec2_user_keypair ? ["ec2-user"] : [],
    var.options.enable_ec2_cloud_watch_agent && fileexists(local.cloud_watch_windows_filename) ? ["cloud-watch-config"] : [],
  ])

  ssm_parameters = {

    account = {
      postfix = "_"
      parameters = {
        ids = {
          description = "Selected modernisation platform AWS account IDs managed by baseline module"
          value = jsonencode({
            for key, value in var.environment.account_ids :
            key => value if contains(local.account_names_for_account_ids_ssm_parameter, key)
          })
        }
      }
    }

    "/azure" = {
      parameters = {
        sas_token = { description = "database backup storage account read-only sas token" }
      }
    }

    cloud-watch-config = {
      postfix = "-"
      parameters = {
        windows = {
          description = "cloud watch agent config for windows managed by baseline module"
          file        = local.cloud_watch_windows_filename
          type        = "String"
        }
      }
    }

    ec2-user = {
      postfix = "_"
      parameters = {
        pem = {
          description = "Private key for ec2-user key pair managed by baseline module"
        }
      }
    }
  }
}

