# KMS Key ID for Kinesis Stream
data "aws_kms_key" "kinesis_kms_key" {
  key_id = aws_kms_key.kinesis-kms-key.arn
}