data "aws_kms_alias" "test_harness_destination" {
  count = var.environment == "test" ? 1 : 0

  name = "alias/s3/integration-hub-file-transfer-test-test-harness"
}