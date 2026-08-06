resource "aws_kms_key" "oracle_ec2" {
  enable_key_rotation = true

  tags = merge(local.tags,
    { Name = "oracle_ec2" }
  )
}

resource "aws_kms_alias" "oracle_ec2_alias" {
  name          = "alias/ec2_oracle_key"
  target_key_id = aws_kms_key.oracle_ec2.arn
}