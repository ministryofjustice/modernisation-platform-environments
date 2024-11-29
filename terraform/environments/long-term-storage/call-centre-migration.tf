resource "aws_s3_bucket" "call_centre" {
  bucket_prefix = "call-centre-migration"
  tags          = local.tags
}

resource "aws_s3_bucket_policy" "call_centre" {
  bucket = aws_s3_bucket.call_centre.id
  policy = data.aws_iam_policy_document.call_centre_bucket_policy.json
}

resource "aws_transfer_server" "call_centre" {
  logging_role                = aws_iam_role.call_centre_transfer_logging.arn
  structured_log_destinations = ["${aws_cloudwatch_log_group.call_centre.arn}:*"]
  tags = merge(
    local.tags,
    { Name = "call-centre-migration" }
  )
}

resource "aws_cloudwatch_log_group" "call_centre" {
  name_prefix       = "call-centre-migration"
  retention_in_days = 365
  tags              = local.tags
}

resource "aws_iam_role" "call_centre_transfer_logging" {
  name_prefix        = "call-centre-migration-logging"
  assume_role_policy = data.aws_iam_policy_document.aws_transfer_assume_role_policy.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachments_exclusive" "call_centre_transfer_logging" {
  policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
  role_name   = aws_iam_role.call_centre_transfer_logging.name
}
