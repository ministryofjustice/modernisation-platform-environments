resource "aws_transfer_server" "this" {
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = "PUBLIC"
  security_policy_name   = "TransferSecurityPolicy-2024-01"
  logging_role           = aws_iam_role.transfer_logging.arn

  tags = {
    Name = var.name
  }
}

resource "aws_iam_role" "transfer_logging" {
  name = "TransferFamilyLoggingRole"

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
