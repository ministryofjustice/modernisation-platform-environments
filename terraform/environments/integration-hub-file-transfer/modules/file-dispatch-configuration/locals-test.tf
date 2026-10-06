locals {
  test = {
    test-harness = {
      "/repository-smoke-test/direct-s3/" = {
        action = {
          name = "push-to-s3"
          push_to_s3 = {
            bucket_id          = "integration-hub-file-transfer-test-test-harness"
            bucket_region      = "eu-west-2"
            destination_prefix = "delivered/repository-smoke-test/direct-s3/"
            kms_key_arn        = var.environment == "test" ? data.aws_kms_alias.test_harness_destination[0].target_key_arn : null
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