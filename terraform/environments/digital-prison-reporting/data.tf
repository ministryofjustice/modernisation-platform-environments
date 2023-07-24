# KMS Key ID for Kinesis Stream
data "aws_kms_key" "kinesis_kms_key" {
  key_id = aws_kms_key.kinesis-kms-key.arn
}

# Source Nomis Secrets
data "aws_secretsmanager_secret" "nomis" {
  name = aws_secretsmanager_secret.nomis.id

  depends_on = [aws_secretsmanager_secret_version.nomis]
}

data "aws_secretsmanager_secret_version" "nomis" {
  secret_id = data.aws_secretsmanager_secret.nomis.id

  depends_on = [aws_secretsmanager_secret.nomis]
}

# AWS _IAM_ Policy
data "aws_iam_policy" "rds_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

# Get APIGateway Endpoint ID
data "aws_vpc_endpoint" "api" {
  provider     = aws.core-vpc
  vpc_id       = data.aws_vpc.shared.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.execute-api"
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-com.amazonaws.${data.aws_region.current.name}.execute-api"
  }
}