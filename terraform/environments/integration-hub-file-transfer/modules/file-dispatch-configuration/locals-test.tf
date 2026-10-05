locals {
  test = {
    test-harness = {
      "/direct-s3/" = {
        action = {
          name = "push-to-s3"
          push_to_s3 = {
            bucket_id          = "integration-hub-file-transfer-test-test-harness"
            bucket_region      = "eu-west-2"
            destination_prefix = "delivered/direct-s3/"
            kms_key_arn        = "arn:aws:kms:eu-west-2:${var.account_id}:key/68e95b1e-2efb-4f51-8958-0eaae6a90a8f"
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