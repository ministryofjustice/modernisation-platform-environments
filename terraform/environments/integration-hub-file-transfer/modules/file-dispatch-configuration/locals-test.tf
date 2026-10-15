locals {
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
    }
  }
}