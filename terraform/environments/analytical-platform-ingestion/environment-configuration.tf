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
      scan_image_version     = "0.0.4"
      transfer_image_version = "0.0.2"

      /* Target Buckets */
      target_buckets = ["dev-ingestion-testing"]

      /* Transfer Server */
      transfer_server_hostname   = "sftp.development.ingestion.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users = {}
      transfer_server_sftp_users_with_egress = {
        "jacobwoffenden-egress" = {
          ssh_key               = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+3qaLVtn6Pd+DasWHhIOBoXEEhF9GZAG+DYfJBeySS Ministry of Justice"
          cidr_blocks           = ["90.246.52.170/32"]
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
      scan_image_version     = "0.0.4"
      transfer_image_version = "0.0.2"

      /* Target Buckets */
      target_buckets = []

      /* Transfer Server */
      transfer_server_hostname               = "sftp.ingestion.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users             = {}
      transfer_server_sftp_users_with_egress = {}
    }
  }
}
