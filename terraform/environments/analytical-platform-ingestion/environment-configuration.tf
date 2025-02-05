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
      scan_image_version     = "0.1.4"
      transfer_image_version = "0.0.19"
      notify_image_version   = "0.0.20"

      /* Target Buckets */
      target_buckets          = ["mojap-land-dev"]
      datasync_target_buckets = ["mojap-land-dev"]

      /* Target KMS */
      mojap_land_kms_key = "arn:aws:kms:eu-west-1:${local.environment_management.account_ids["analytical-platform-data-production"]}:key/8c53fbac-3106-422a-8f3d-409bb3b0c94d"

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

      /* DataSync */
      datasync_instance_private_ip = "10.26.128.5"
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

      /* Transit Gateway */
      transit_gateway_routes = [
        /* Send all traffic not destined for local down to the transit gateway */
        "10.0.0.0/8"
      ]

      /* Image Versions */
      scan_image_version     = "0.1.4"
      transfer_image_version = "0.0.19"
      notify_image_version   = "0.0.20"

      /* Target Buckets */
      target_buckets          = ["mojap-land"]
      datasync_target_buckets = ["mojap-land"]

      /* Target KMS */
      mojap_land_kms_key = "arn:aws:kms:eu-west-1:${local.environment_management.account_ids["analytical-platform-data-production"]}:key/2855ac30-4e14-482e-85ca-53258e01f64c"

      /* Transfer Server */
      transfer_server_hostname = "sftp.ingestion.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users = {
        "sscl-chris-j" = {
          ssh_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAx1BrX2NaosOZiGrfvuMYU08aycG/IlBO9FuZFAnXjLTGzw7BABkEJgCG6BHQydJymQIVNxhM9558p/l3CuAA7ItXncRLNNZ4eSLs2x81amEujV7KOuan28LSKU4yd5K+bCUOnpq35w0XEeYrwvEUHgrlR75FWumrus3rpv7xSbz4+7YqtweVOREUNew8Md/1jJpr26CHgn1VqtLKWzUOVU/UjKlKhr+dH7CbFGaux0Le+ntvD04TL91fx3yGFBN23Ybw+epGNhVFlPKuFfr++SDbF5M22jFu1lMtL96CPEVgTMYgcwRLeX51CrykmezFq1YEY//w2JDw8PKbDYF2ouLZLexh0M9l95VvejNNGx2BIEkfblXH8zWIWPu6D9ju6HOzucqKTctjLioZGVoaBwZA8MG8KvS887+4R611VNxZ05PxGJiIqWAcwgDKl91uFuzOkWXmoWXALqyI/QEMO5CU3JoUsZhHY4+eEnxyIoN1xqB4XSUwsvY0/hRZs2bvnTgKIPkwjqckhytpuTT6L8oAhSLDaUyBhy216pIBgq0EFRpStdLa2R3PQrrXalxl4ooyz3AeshnIUi4WslXRnw7/WUcgOeV5i8jqQmygvLlLjAtyAT+zsC0ItXsDzrovN9dpTTHmsPwr3ZGM9TmdrVZC7h3ZOkbrckhfVLtE8wU="
          cidr_blocks = ["51.140.183.67/32"]
        }
      }
      transfer_server_sftp_users_with_egress = {
        "essex-police" = {
          ssh_key               = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpNyYzfbqmy4QkViLRyASRqxrEK7G34o3Bc6Jdp8vK555/oBuAUXUxfavtenZnxuxdxsrBYBSCBFcU4+igeXN/nN2kVfaUlt1xBZBCRUaajinhmt+3CLbr8bWmHR/5vL/DhxHH+j/+gDH5A244XN/ybZQvCGX/ilgKiae8s0tiOZD2hmX0fhRTCohQFG/DIu06gqKIyxUQoHBoBJxjzaDvjqioJgqmD9893DN+Gx1KozmaQWHM+0f7iK1UFp8BkdeFBVkj8TOfx60o/EmAjWQ/U+WSHblaXo0nI+LQKZYkW52uTEnfSkbkyvs/vj8E8+vagwYi0noyTVmb5qReSuk1kyuqEP2ycKIaWKt+Z4LnwxHm7KO51SMMeBgpiFHaUTQWXZHYuU2aXVfFIgJkCtHdEjG7Qe2P8K5XU5rG+CrQ/Y9PxPrKQHk+2nox9dLfCWo2Eho1N85z9/rA7A0oNwsHkjWAl3k87lWdpg7y3VNLzqsMNF4M4HjpQV60MH73dUU= essex-police@kpvmshift04app.netr.ecis.police.uk"
          cidr_blocks           = ["194.74.29.178/32"]
          egress_bucket         = module.bold_egress_bucket.s3_bucket_id
          egress_bucket_kms_key = module.s3_bold_egress_kms.key_arn
        }
      }

      /* DataSync */
      datasync_instance_private_ip = "10.27.128.5"
    }
  }
}
