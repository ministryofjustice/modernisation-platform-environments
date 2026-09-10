resource "aws_iam_role" "dms_vpc" {
  count = local.dms_core_enabled ? 1 : 0

  name        = "dms-vpc-role"
  description = "AWS DMS service role for VPC access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "dms.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "dms-vpc-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "dms_vpc" {
  count = local.dms_core_enabled ? 1 : 0

  role       = aws_iam_role.dms_vpc[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

resource "aws_iam_role" "dms_cloudwatch_logs" {
  count = local.dms_core_enabled ? 1 : 0

  name        = "dms-cloudwatch-logs-role"
  description = "AWS DMS service role for CloudWatch Logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "dms.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "dms-cloudwatch-logs-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "dms_cloudwatch_logs" {
  count = local.dms_core_enabled ? 1 : 0

  role       = aws_iam_role.dms_cloudwatch_logs[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}
