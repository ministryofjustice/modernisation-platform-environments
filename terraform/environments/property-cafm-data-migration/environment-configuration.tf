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
      transfer_server_sftp_users = {
        "test_user" = {
          ssh_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCWz7ue/saomMAKrVgo6FifjpGQfl7B4fs2s/MJa2jhpBVWXk9tquGDXp1/Yfk4C7FIneGKfh8fWHz9FPS+u6h3a9hMW8d/5onNuSr9S6T2mN7ydZQzGez5qyG2vNFLyip3ls6mQjIpXSo2aow7+3Y2lbDe8UamiYNVgvvWB+hVl5RJjcaReDDbi0xwdjGjep0LcvgAyKa8evmcEbFVkrLhWyc30xn1+OesqPWSpoIb/IlBDFxCqR46GW/zlOldEIatONhXWgvJ6dS5T1YmHsE4U0Py3BV8O5zvc+XRYjr/3w9LOwmTHS1xbzlhNBjO1o6O9hSBsowBjsWLL5aNWcdBH0DiWfIWkoq9Fy8VEAa/T5v7GCaKvDs9pGBpjQSQsWyKXbwP0Z2RGyU2CSGVzMM6gzrjaxanOK9QbLOqCpTSSIYWfokt+MNrHcQU+9mBTjq20URF7RW6tsM8GvzGRNk0hlkX3ueq86uLpQzRctGBTjN74qBba0WbauIcSl4OIrc+NEwjaFTmuIs0NIG5aoAop8WHOC8cxFAST2XjMF30eEh6/W9Gh0uPor4L5tUqJ/JuI2wcfYLuk1KLDcOUVin79QficX93zbaTPNXWW052ct50B0KnCmZyvQORwOH8gBFgkFe5MO/bqevG9Xpof/QvpCLKEON/fBAW4bEdIIv5qw=="
          cidr_blocks = ["51.11.176.157/32"]
        }
      }
      /* DataSync */
      datasync_instance_private_ip = "10.26.128.5"
    }
  }
}
