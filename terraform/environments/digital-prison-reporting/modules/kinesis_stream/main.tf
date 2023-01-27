resource "aws_kinesis_stream" "this" {
  count = var.create_kinesis_stream ? 1 : 0

  name = var.name
  # shard_count             = var.shard_count # Not require in On-Demand Mode
  retention_period          = var.retention_period
  shard_level_metrics       = var.shard_level_metrics
  enforce_consumer_deletion = var.enforce_consumer_deletion
  encryption_type           = var.encryption_type
  kms_key_id                = var.kms_key_id
  tags                      = var.tags

  stream_mode_details {
    stream_mode = "ON_DEMAND" # Changing to ON_DEMAND
  }

  #  // Ignore future changes on the desired count value
  #  lifecycle {
  #    ignore_changes = [shard_count]
  #  }

}

resource "aws_iam_policy" "read-only" {
  count = var.create_policy_read_only && var.create_kinesis_stream ? 1 : 0

  name        = "${var.name}-read"
  path        = "/"
  description = "Managed by Terraform"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat([
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeLimits",
          "kinesis:DescribeStream",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:SubscribeToShard",
          "kinesis:ListShards"
        ]
        Resource = [
          aws_kinesis_stream.this[count.index].arn
        ]
      }
    ])
  })

  tags = var.tags
}

resource "aws_iam_policy" "write-only" {
  count = var.create_policy_write_only && var.create_kinesis_stream ? 1 : 0

  name        = "${var.name}-write"
  path        = "/"
  description = "Managed by Terraform"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat([
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:PutRecord",
          "kinesis:PutRecords",
        ]
        Resource = [
          aws_kinesis_stream.this[count.index].arn
        ]
      }
    ])
  })

  tags = var.tags

}

resource "aws_iam_policy" "admin" {
  count = var.create_policy_admin && var.create_kinesis_stream ? 1 : 0

  name        = "${var.name}-admin"
  path        = "/"
  description = "Managed by Terraform"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat([
      {
        Effect = "Allow"
        Action = [
          "kinesis:*",
        ]
        Resource = [
          aws_kinesis_stream.this[count.index].arn
        ]
      }
    ])
  })
}


#### TEMPORARY ####
#resource "aws_iam_role_policy_attachment" "temporary-policy" {
#  role       = "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/AWSReservedSSO_modernisation-platform-developer_1425a99d62c4ce2b"
#  policy_arn = concat(aws_iam_policy.admin.*.arn, [""])[0]
#}