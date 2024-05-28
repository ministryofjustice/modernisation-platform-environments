locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      /* VPC */
      vpc_cidr                   = "10.0.0.0/16"
      vpc_private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      vpc_public_subnets         = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true

      /* Observability Platform */
      observability_platform = "development"

      /* Image Versions */
      scan_image_version     = "0.0.6"
      transfer_image_version = "0.0.11"
      notify_image_version   = "0.0.12"

      /* Target Buckets */
      target_buckets = ["mojap-land-dev"]

      /* Transfer Server */
      transfer_server_hostname   = "sftp.development.ingestion.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users = {}
      transfer_server_sftp_users_with_egress = {
        "essex-police" = {
          ssh_key               = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCv3JdWZ/2NGd8KKaeICIjqw5zwI2NtzQSWtvscfKZS lalitha.nagarur@digital.justice.gov.uk"
          cidr_blocks           = ["213.121.161.124/32", "2.99.13.52/32", "78.150.12.143/32"]
          egress_bucket         = module.bold_egress_bucket.s3_bucket_id
          egress_bucket_kms_key = module.s3_bold_egress_kms.key_arn
        }
      }
    }
    production = {
      /* VPC */
      vpc_cidr                   = "10.0.0.0/16"
      vpc_private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      vpc_public_subnets         = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
      vpc_enable_nat_gateway     = true
      vpc_one_nat_gateway_per_az = true

      /* Observability Platform */
      observability_platform = "production"

      /* Image Versions */
      scan_image_version     = "0.0.6"
      transfer_image_version = "0.0.11"
      notify_image_version   = "0.0.12"

      /* Target Buckets */
      target_buckets = ["mojap-land"]

      /* Transfer Server */
      transfer_server_hostname               = "sftp.ingestion.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users             = {}
      transfer_server_sftp_users_with_egress = {}
    }
  }
}
