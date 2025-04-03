locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      /* Transfer Server */
      transfer_server_hostname = "sftp.development.transfer.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users = {
        "gary-test" = {
          ssh_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCWz7ue/saomMAKrVgo6FifjpGQfl7B4fs2s/MJa2jhpBVWXk9tquGDXp1/Yfk4C7FIneGKfh8fWHz9FPS+u6h3a9hMW8d/5onNuSr9S6T2mN7ydZQzGez5qyG2vNFLyip3ls6mQjIpXSo2aow7+3Y2lbDe8UamiYNVgvvWB+hVl5RJjcaReDDbi0xwdjGjep0LcvgAyKa8evmcEbFVkrLhWyc30xn1+OesqPWSpoIb/IlBDFxCqR46GW/zlOldEIatONhXWgvJ6dS5T1YmHsE4U0Py3BV8O5zvc+XRYjr/3w9LOwmTHS1xbzlhNBjO1o6O9hSBsowBjsWLL5aNWcdBH0DiWfIWkoq9Fy8VEAa/T5v7GCaKvDs9pGBpjQSQsWyKXbwP0Z2RGyU2CSGVzMM6gzrjaxanOK9QbLOqCpTSSIYWfokt+MNrHcQU+9mBTjq20URF7RW6tsM8GvzGRNk0hlkX3ueq86uLpQzRctGBTjN74qBba0WbauIcSl4OIrc+NEwjaFTmuIs0NIG5aoAop8WHOC8cxFAST2XjMF30eEh6/W9Gh0uPor4L5tUqJ/JuI2wcfYLuk1KLDcOUVin79QficX93zbaTPNXWW052ct50B0KnCmZyvQORwOH8gBFgkFe5MO/bqevG9Xpof/QvpCLKEON/fBAW4bEdIIv5qw=="
          cidr_blocks = ["1.2.3.4/32"]
        }
      }
      transfer_server_sftp_users_with_egress = {
        "gary-test-egress" = {
          ssh_key               = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpNyYzfbqmy4QkViLRyASRqxrEK7G34o3Bc6Jdp8vK555/oBuAUXUxfavtenZnxuxdxsrBYBSCBFcU4+igeXN/nN2kVfaUlt1xBZBCRUaajinhmt+3CLbr8bWmHR/5vL/DhxHH+j/+gDH5A244XN/ybZQvCGX/ilgKiae8s0tiOZD2hmX0fhRTCohQFG/DIu06gqKIyxUQoHBoBJxjzaDvjqioJgqmD9893DN+Gx1KozmaQWHM+0f7iK1UFp8BkdeFBVkj8TOfx60o/EmAjWQ/U+WSHblaXo0nI+LQKZYkW52uTEnfSkbkyvs/vj8E8+vagwYi0noyTVmb5qReSuk1kyuqEP2ycKIaWKt+Z4LnwxHm7KO51SMMeBgpiFHaUTQWXZHYuU2aXVfFIgJkCtHdEjG7Qe2P8K5XU5rG+CrQ/Y9PxPrKQHk+2nox9dLfCWo2Eho1N85z9/rA7A0oNwsHkjWAl3k87lWdpg7y3VNLzqsMNF4M4HjpQV60MH73dUU= essex-police@kpvmshift04app.netr.ecis.police.uk"
          cidr_blocks           = ["1.1.2.3/32"]
          egress_bucket         = module.transfer_landing_bucket.s3_bucket_id # this is wrong. purely for testing
          egress_bucket_kms_key = module.s3_transfer_landing_kms.key_arn      # this is wrong. purely for testing
        }
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
