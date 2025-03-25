locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      /* VPC */
      isolated_vpc_public_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
      isolated_vpc_private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      isolated_vpc_id              = "vpc-0902ef7a6188ef9a0"

      /* Transfer Server */
      transfer_server_hostname = "sftp.development.transfer.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users = {

      }
      transfer_server_sftp_users_with_egress = {

      }
    }
    production = {
      /* VPC */
      isolated_vpc_public_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
      isolated_vpc_private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      isolated_vpc_cidr            = ""

      /* Transfer Server */
      transfer_server_hostname = "sftp.development.transfer.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users = {

      }
      transfer_server_sftp_users_with_egress = {

      }
    }
  }
}
