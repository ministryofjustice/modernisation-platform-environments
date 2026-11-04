data "aws_kms_alias" "test_harness_destination" {
  count = var.environment == "test" ? 1 : 0

  name = "alias/s3/integration-hub-file-transfer-test-test-harness"
}

# The test harness creates the SFTP server and calculates its IP address separately.
# If you change the subnet or address calculation here, update the test harness too.
# Both must use the same IP address for file delivery to work.
data "aws_vpc" "test_sftp" {
  count = var.environment == "test" ? 1 : 0

  tags = { Name = "platforms-${var.environment}" }
}

data "aws_subnets" "test_sftp" {
  count = var.environment == "test" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.test_sftp[0].id]
  }
  tags = { Name = "platforms-${var.environment}-general-private*" }
}

data "aws_subnet" "test_sftp" {
  count = var.environment == "test" ? 1 : 0

  id = sort(data.aws_subnets.test_sftp[0].ids)[0]
}

locals {
  test_sftp_server_ip = var.environment == "test" ? cidrhost(data.aws_subnet.test_sftp[0].cidr_block, 100) : null

  test_harness_destination_kms_key_arn = one(
    data.aws_kms_alias.test_harness_destination[*].target_key_arn
  )

  test = {
    test-harness = {
      "/push-to-s3/" = {
        action = {
          name = "push-to-s3"
          push_to_s3 = {
            bucket_id          = "integration-hub-file-transfer-test-test-harness"
            bucket_region      = "eu-west-2"
            destination_prefix = "push-to-s3/"
            kms_key_arn        = local.test_harness_destination_kms_key_arn
          }
        }
        notifications = {
          email = null
          slack = null
          teams = null
        }
      }

      "/push-to-sftp/" = {
        action = {
          name = "push-to-sftp"
          push_to_sftp = {
            hostname           = local.test_sftp_server_ip
            port               = 22
            username           = "hubtest"
            destination_prefix = "incoming/"
            # Public host key; the matching private key is in the test-harness host-key secret.
            host_public_keys        = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYvbJuLvL2auHSZe83WPDgW7Hs03eeblJY4uM1bNeVN"]
            destination_cidr_blocks = var.environment == "test" ? ["${local.test_sftp_server_ip}/32"] : []
          }
        }
        notifications = {
          email = null
          slack = null
          teams = null
        }
      }

      "/hosted-pickup/" = {
        action = {
          name = "push-to-s3-with-hosted-pickup"
          push_to_s3_with_hosted_pickup = {
            destination_prefix = "pickup/"
            retention_days     = 1
          }
        }
        notifications = {
          email = null
          slack = null
          teams = null
        }
      }

      "/pull-from-presigned-url/" = {
        # The notification component retains the clean copy for the access-control test.
        action = null
        notifications = {
          email = null
          slack = "test-harness-presigned"
          teams = null
        }
        pickup = {
          recipient_id = "test-harness-presigned"
          # Existing web-app membership is managed by root; this grants pickup reads only.
          authorised_groups = {
            azure-aws-sso-integration-hub = "1622e2b4-9011-7000-b2fc-87228b7308cd"
          }
          slack_channel_id = "C0CEGV299DJ" # integration-hub-test-alerts
          slack_team_id    = "T02DYEB3A"   # Justice Digital
        }
      }
    }
  }
}