locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      /* VPC */
      connected_vpc_cidr            = "10.26.128.0/23"
      connected_vpc_private_subnets = ["10.26.128.0/26", "10.26.128.64/26", "10.26.128.128/26"]
      connected_vpc_public_subnets  = ["10.26.129.0/26", "10.26.129.64/26", "10.26.129.128/26"]

      isolated_vpc_cidr                   = "10.0.0.0/16"
      isolated_vpc_private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      isolated_vpc_public_subnets         = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
      isolated_vpc_enable_nat_gateway     = true
      isolated_vpc_one_nat_gateway_per_az = true

      /* Transit Gateway */
      transit_gateway_routes = [
        /* Send all traffic not destined for local down to the transit gateway */
        "10.0.0.0/8"
      ]

      /* Image Versions */
      scan_image_version     = "0.1.6"
      transfer_image_version = "0.0.21"
      notify_image_version   = "0.0.22"

      /* Target Buckets */
      target_buckets              = ["property-datahub-landing-development"]
      datasync_target_buckets     = ["property-datahub-landing-development"]

      /* Transfer Server */
      transfer_server_hostname = "sftp.development.ingestion.cafm-migration.service.justice.gov.uk"

      /* DataSync */
      datasync_instance_private_ip = "10.26.128.5"
    }
  }
}
