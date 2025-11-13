### S3 BUCKET FOR WORKSPACES WEB SESSION LOGGING

module "s3_bucket_workspacesweb_session_logs" {
  count = local.create_resources ? 1 : 0

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = "laa-workspacesweb-session-logs-${random_string.bucket_suffix[0].result}"
  force_destroy = true

  # Versioning
  versioning = {
    enabled = true
  }

  # Server side encryption with KMS
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.workspacesweb_session_logs[0].arn
      }
    }
  }

  # Public access block
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Lifecycle configuration
  lifecycle_rule = [{
    id     = "session_logs_lifecycle"
    status = "Enabled"

    expiration = {
      days = 365
    }

    noncurrent_version_expiration = {
      days = 30
    }
  }]

  # Bucket policy using the IAM policy document
  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_bucket_policy[0].json

  tags = merge(
    local.tags,
    {
      Name = "laa-workspacesweb-session-logs"
    }
  )
}

resource "random_string" "bucket_suffix" {
  count = local.create_resources ? 1 : 0

  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_notification" "s3_bucket_workspacesweb_session_logs" {
  count  = local.create_resources ? 1 : 0
  bucket = module.s3_bucket_workspacesweb_session_logs[0].s3_bucket_id
  queue {
    id            = "workspaces-web-logs"
    queue_arn     = module.sqs_s3_notifications[0].queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "workspaces-web-logs/"
  }
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  count = local.create_resources ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["workspaces-web.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::laa-workspacesweb-session-logs-${random_string.bucket_suffix[0].result}",
      "arn:aws:s3:::laa-workspacesweb-session-logs-${random_string.bucket_suffix[0].result}/*"
    ]
  }
}

####################
# S3 bucket for CloudFront origin (waiting room page)
####################
resource "aws_s3_bucket" "waiting_room" {
  count = local.create_resources ? 1 : 0

  bucket        = "laa-workspaces-waiting-room-${random_id.waiting_room_suffix[0].hex}"
  force_destroy = true

  tags = merge(
    local.tags,
    {
      Name = "laa-workspaces-waiting-room"
    }
  )
}

resource "random_id" "waiting_room_suffix" {
  count = local.create_resources ? 1 : 0

  byte_length = 4
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "waiting_room" {
  count = local.create_resources ? 1 : 0

  bucket = aws_s3_bucket.waiting_room[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront origin access identity and bucket policy so CF can read the bucket
resource "aws_cloudfront_origin_access_identity" "waiting_room" {
  count = local.create_resources ? 1 : 0

  comment = "OAI for WorkSpaces Web waiting room"
}

data "aws_iam_policy_document" "waiting_room_s3_policy" {
  count = local.create_resources ? 1 : 0

  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.waiting_room[0].iam_arn]
    }
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.waiting_room[0].arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "waiting_room_policy" {
  count = local.create_resources ? 1 : 0

  bucket = aws_s3_bucket.waiting_room[0].id
  policy = data.aws_iam_policy_document.waiting_room_s3_policy[0].json
}

# Waiting room index page
resource "aws_s3_object" "index" {
  count = local.create_resources ? 1 : 0

  bucket       = aws_s3_bucket.waiting_room[0].id
  key          = "index.html"
  content_type = "text/html"
  content      = <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>LAA WorkSpaces Web - Authentication</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f4f4f4;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
    }
    .container {
      background: white;
      padding: 40px;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
      text-align: center;
      max-width: 500px;
    }
    h1 {
      color: #333;
      margin-bottom: 20px;
    }
    p {
      color: #666;
      line-height: 1.6;
    }
    .info {
      background: #e8f4f8;
      padding: 15px;
      border-radius: 4px;
      margin-top: 20px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>LAA WorkSpaces Web</h1>
    <h2>Authentication Required</h2>
    <p>You are being redirected to authenticate with Microsoft Entra ID.</p>
    <div class="info">
      <p><strong>Note:</strong> Use the CloudFront URL with <code>?login_hint=your-email@example.com</code> to pre-fill your email address.</p>
    </div>
  </div>
</body>
</html>
HTML

  tags = merge(
    local.tags,
    {
      Name = "waiting-room-index"
    }
  )
}

# OAuth callback page - extracts token from fragment and calls API Gateway
resource "aws_s3_object" "callback" {
  count = local.create_resources ? 1 : 0

  bucket       = aws_s3_bucket.waiting_room[0].id
  key          = "callback.html"
  content_type = "text/html"
  content = templatefile("${path.module}/s3-content/callback.html", {
    LAMBDA_URL = aws_lambda_function_url.callback[0].function_url
  })

  tags = merge(
    local.tags,
    {
      Name = "oauth-callback-page"
    }
  )
}
