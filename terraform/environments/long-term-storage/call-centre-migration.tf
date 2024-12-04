resource "aws_cloudwatch_log_group" "call_centre" {
  name_prefix       = "call-centre-migration"
  retention_in_days = 365
  tags              = local.tags
}

resource "aws_kms_key" "call_centre" {
  enable_key_rotation     = true
  rotation_period_in_days = 90
  tags                    = local.tags
}

resource "aws_kms_key_policy" "call_centre" {
  key_id = aws_kms_key.call_centre.id
  policy = data.aws_iam_policy_document.call_centre_kms_policy.json
}

resource "aws_s3_bucket" "call_centre" {
  bucket_prefix = "call-centre-migration"
  tags          = local.tags
}

resource "aws_s3_bucket_policy" "call_centre" {
  bucket = aws_s3_bucket.call_centre.id
  policy = data.aws_iam_policy_document.call_centre_bucket_policy.json
}

resource "aws_s3_bucket_server_side_encryption_configuration" "call_centre" {
  bucket = aws_s3_bucket.call_centre.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.call_centre.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_secretsmanager_secret" "call_centre" {
  description                    = "Secret containing key-value pairs for AWS Transfer connector."
  force_overwrite_replica_secret = true
  name                           = "aws/transfer/${aws_transfer_server.call_centre.id}/call-centre"
  recovery_window_in_days        = 0
  tags                           = local.tags
}

# Because we populate the secret version manually, we refer to its contents with a data call
data "aws_secretsmanager_secret_version" "call_centre" {
  secret_id = aws_secretsmanager_secret.call_centre.id
}

resource "aws_transfer_server" "call_centre" {
  logging_role                = aws_iam_role.call_centre_transfer_logging.arn
  structured_log_destinations = ["${aws_cloudwatch_log_group.call_centre.arn}:*"]
  tags = merge(
    local.tags,
    { Name = "call-centre-migration" }
  )
}

resource "aws_transfer_connector" "call_centre" {
  access_role = aws_iam_role.call_centre_transfer_access.arn
  sftp_config {
    trusted_host_keys = [jsondecode(data.aws_secretsmanager_secret_version.call_centre.secret_string)["Fingerprint"]]
    user_secret_id    = aws_secretsmanager_secret.call_centre.id
  }
  url = jsondecode(data.aws_secretsmanager_secret_version.call_centre.secret_string)["Hostname"]
}

resource "aws_iam_role" "call_centre_transfer_logging" {
  name_prefix        = "call-centre-migration-logging"
  assume_role_policy = data.aws_iam_policy_document.aws_transfer_assume_role_policy.json
  tags               = local.tags
}

resource "aws_iam_role" "call_centre_transfer_access" {
  name_prefix        = "call-centre-access"
  assume_role_policy = data.aws_iam_policy_document.aws_transfer_assume_role_policy.json
  tags               = local.tags
}

resource "aws_iam_policy" "call_centre_transfer_access" {
  description = "Access policy for AWS Transfer connector."
  name_prefix = "call-centre-access"
  policy      = data.aws_iam_policy_document.call_centre_access_policy.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "call_centre_transfer_access" {
  policy_arn = aws_iam_policy.call_centre_transfer_access.arn
  role       = aws_iam_role.call_centre_transfer_access.name
}

resource "aws_iam_role_policy_attachments_exclusive" "call_centre_transfer_logging" {
  policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
  role_name   = aws_iam_role.call_centre_transfer_logging.name
}