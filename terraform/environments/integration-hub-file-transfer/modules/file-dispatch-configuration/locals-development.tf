locals {
  development = {
    products-poc = {
      "/uploads/" = {
        # The notification component retains the clean copy for this API trial.
        action = null
        notifications = {
          email = null
          slack = "products-poc-slack-test"
          teams = null
        }
        pickup = {
          recipient_id = "products-poc-slack-test"
          # Existing web-app membership is managed by root; this grants pickup reads only.
          authorised_groups = {
            azure-aws-sso-integration-hub = "1622e2b4-9011-7000-b2fc-87228b7308cd"
          }
          slack_channel_id = "C0CAB9Q6S2U" # integration-hub-alerts
          slack_team_id    = "T02DYEB3A"   # Justice Digital
        }
      }
    }

    dms1981 = {
      "/push-to-sftp/" = {
        action = {
          name = "push-to-sftp"
          push_to_sftp = {
            hostname                = "sftp.test.file-transfer.service.justice.gov.uk"
            port                    = 22
            username                = "dms1981@development.file-transfer.service.justice.gov.uk"
            destination_prefix      = ""
            host_public_keys        = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA50Zlk/twXrQJL/+boIvxSW69PKtrMli88LaQuJ6bTh"]
            destination_cidr_blocks = ["13.41.214.181/32"]
          }
        }
        notifications = {
          email = null
          slack = null
          teams = null
        }
      }

      "/" = {
        action = {
          name = "push-to-s3-with-hosted-pickup"
          push_to_s3_with_hosted_pickup = {
            destination_prefix = "pickup/"
            retention_days     = 7
          }
        }
        notifications = {
          email = null
          slack = null
          teams = null
        }
      }
    }
  }
}