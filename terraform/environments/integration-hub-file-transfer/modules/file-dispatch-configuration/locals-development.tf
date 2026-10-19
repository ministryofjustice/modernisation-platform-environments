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
            integration-hub = "8662e2b4-3021-7017-56ba-8794aa2047cd"
          }
          slack_channel_id = "C0CAB9Q6S2U" # integration-hub-alerts
          slack_team_id    = "T02DYEB3A"   # Justice Digital
        }
      }
    }

    dms1981 = {
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