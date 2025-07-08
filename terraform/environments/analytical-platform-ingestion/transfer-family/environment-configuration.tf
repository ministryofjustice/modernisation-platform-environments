locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      /* Transfer Server */
      transfer_server_hostname = "sftp.development.transfer.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users = {

      }
      transfer_server_sftp_users_with_egress = {

      }
    }
    production = {
      /* Transfer Server */
      transfer_server_hostname = "sftp.transfer.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users = {

      }
      transfer_server_sftp_users_with_egress = {

      }
    }
  }
}
