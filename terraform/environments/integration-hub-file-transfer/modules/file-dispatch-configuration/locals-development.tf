locals {
  development = {
    dms1981 = {
      "/" = {
        action = null
        notifications = {
          email = null
          slack = null
          teams = null
        }
      }
      "/push-to-s3-with-hosted-pickup/" = {
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