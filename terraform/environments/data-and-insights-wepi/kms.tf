# Customer-managed KMS key for at-rest encryption, key rotation enabled
resource "aws_kms_key" "wepi_kms_cmk" {
  description         = "Customer-managed key for DIH at-rest encryption"
  enable_key_rotation = true

  tags = merge(
    local.tags,
    {
      Name = "wepi-kms-${local.environment}-cmk"
    }
  )
}