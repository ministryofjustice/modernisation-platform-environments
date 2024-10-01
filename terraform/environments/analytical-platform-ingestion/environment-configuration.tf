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

      /* Observability Platform */
      observability_platform = "development"

      /* Image Versions */
      scan_image_version     = "0.0.9"
      transfer_image_version = "0.0.14"
      notify_image_version   = "0.0.15"

      /* Target Buckets */
      target_buckets = ["mojap-land-dev"]

      /* Transfer Server */
      transfer_server_hostname   = "sftp.development.ingestion.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users = {}
      transfer_server_sftp_users_with_egress = {
        "essex-police" = {
          ssh_key               = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpNyYzfbqmy4QkViLRyASRqxrEK7G34o3Bc6Jdp8vK555/oBuAUXUxfavtenZnxuxdxsrBYBSCBFcU4+igeXN/nN2kVfaUlt1xBZBCRUaajinhmt+3CLbr8bWmHR/5vL/DhxHH+j/+gDH5A244XN/ybZQvCGX/ilgKiae8s0tiOZD2hmX0fhRTCohQFG/DIu06gqKIyxUQoHBoBJxjzaDvjqioJgqmD9893DN+Gx1KozmaQWHM+0f7iK1UFp8BkdeFBVkj8TOfx60o/EmAjWQ/U+WSHblaXo0nI+LQKZYkW52uTEnfSkbkyvs/vj8E8+vagwYi0noyTVmb5qReSuk1kyuqEP2ycKIaWKt+Z4LnwxHm7KO51SMMeBgpiFHaUTQWXZHYuU2aXVfFIgJkCtHdEjG7Qe2P8K5XU5rG+CrQ/Y9PxPrKQHk+2nox9dLfCWo2Eho1N85z9/rA7A0oNwsHkjWAl3k87lWdpg7y3VNLzqsMNF4M4HjpQV60MH73dUU= essex-police@kpvmshift04app.netr.ecis.police.uk"
          cidr_blocks           = ["194.74.29.178/32"]
          egress_bucket         = module.bold_egress_bucket.s3_bucket_id
          egress_bucket_kms_key = module.s3_bold_egress_kms.key_arn
        }
      }
    }
    production = {
      /* VPC */
      connected_vpc_cidr            = "10.27.128.0/23"
      connected_vpc_private_subnets = ["10.27.128.0/26", "10.27.128.64/26", "10.27.128.128/26"]
      connected_vpc_public_subnets  = ["10.27.129.0/26", "10.27.129.64/26", "10.27.129.128/26"]

      isolated_vpc_cidr                   = "10.0.0.0/16"
      isolated_vpc_private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      isolated_vpc_public_subnets         = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
      isolated_vpc_enable_nat_gateway     = true
      isolated_vpc_one_nat_gateway_per_az = true

      /* Observability Platform */
      observability_platform = "production"

      /* Image Versions */
      scan_image_version     = "0.0.9"
      transfer_image_version = "0.0.14"
      notify_image_version   = "0.0.15"

      /* Target Buckets */
      target_buckets = ["mojap-land"]

      /* Transfer Server */
      transfer_server_hostname   = "sftp.ingestion.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users = {}
      transfer_server_sftp_users_with_egress = {
        "essex-police" = {
          ssh_key               = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpNyYzfbqmy4QkViLRyASRqxrEK7G34o3Bc6Jdp8vK555/oBuAUXUxfavtenZnxuxdxsrBYBSCBFcU4+igeXN/nN2kVfaUlt1xBZBCRUaajinhmt+3CLbr8bWmHR/5vL/DhxHH+j/+gDH5A244XN/ybZQvCGX/ilgKiae8s0tiOZD2hmX0fhRTCohQFG/DIu06gqKIyxUQoHBoBJxjzaDvjqioJgqmD9893DN+Gx1KozmaQWHM+0f7iK1UFp8BkdeFBVkj8TOfx60o/EmAjWQ/U+WSHblaXo0nI+LQKZYkW52uTEnfSkbkyvs/vj8E8+vagwYi0noyTVmb5qReSuk1kyuqEP2ycKIaWKt+Z4LnwxHm7KO51SMMeBgpiFHaUTQWXZHYuU2aXVfFIgJkCtHdEjG7Qe2P8K5XU5rG+CrQ/Y9PxPrKQHk+2nox9dLfCWo2Eho1N85z9/rA7A0oNwsHkjWAl3k87lWdpg7y3VNLzqsMNF4M4HjpQV60MH73dUU= essex-police@kpvmshift04app.netr.ecis.police.uk"
          cidr_blocks           = ["194.74.29.178/32"]
          egress_bucket         = module.bold_egress_bucket.s3_bucket_id
          egress_bucket_kms_key = module.s3_bold_egress_kms.key_arn
        }
      }
    }
  }
}
