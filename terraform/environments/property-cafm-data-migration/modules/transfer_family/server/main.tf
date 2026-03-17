resource "aws_transfer_server" "this" {
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = "PUBLIC"
  security_policy_name   = "TransferSecurityPolicy-2024-01"

  logging_role = aws_iam_role.transfer_logging.arn

  structured_log_destinations = [
    aws_cloudwatch_log_group.transfer.arn
  ]

  depends_on = [
    aws_cloudwatch_log_group.transfer
  ]

  tags = var.tags
}

resource "aws_iam_role" "transfer_logging" {
  name = "TransferFamilyLoggingRole-${var.tags["Name"]}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "transfer.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "transfer_logging_policy" {
  role       = aws_iam_role.transfer_logging.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
}

resource "aws_cloudwatch_log_group" "transfer" {
  name              = "/aws/transfer/${var.tags["Name"]}"
  retention_in_days = 365
  tags = var.tags
}
