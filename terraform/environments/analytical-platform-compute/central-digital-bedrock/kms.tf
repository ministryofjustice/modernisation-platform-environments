# KMS key for RDS vector database encryption
resource "aws_kms_key" "vector_db_kms" {
  description             = "KMS key for Bedrock vector database encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = local.tags
}

resource "aws_kms_alias" "vector_db_kms" {
  name          = "alias/bedrock/vector-db"
  target_key_id = aws_kms_key.vector_db_kms.key_id
}