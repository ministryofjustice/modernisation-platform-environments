resource "aws_s3_bucket" "call_center" {
  bucket_prefix = "call-center-migration"
  tags          = local.tags
}

resource "aws_transfer_server" "call_center" {
  logging_role                = aws_iam_role.call_center_transfer_logging_role.arn
  structured_log_destinations = ["${aws_cloudwatch_log_group.call_center.arn}:*"]
  tags = merge(
    local.tags,
    { Name = "call-center-migration" }
  )
}

resource "aws_cloudwatch_log_group" "call_center" {
  name_prefix       = "call-center-migration"
  retention_in_days = 365
  tags              = local.tags
}

resource "aws_iam_role" "call_center_transfer_logging_role" {
  name_prefix        = "call-center-migration"
  assume_role_policy = data.aws_iam_policy_document.call_center_transfer_assume_role_policy.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachments_exclusive" "call_center_transfer_logging_policy" {
  policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
  role_name   = aws_iam_role.call_center_transfer_logging_role.name
}
