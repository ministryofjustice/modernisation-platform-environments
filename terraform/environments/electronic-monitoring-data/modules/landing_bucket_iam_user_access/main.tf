resource "aws_iam_user" "supplier" {
  name = "${var.local_bucket_prefix}-${var.data_feed}-${var.order_type}"
  tags = merge(
    var.local_tags,
    { order_type = var.order_type },
    { data_feed = var.data_feed }
  )
}

resource "aws_iam_user_policy" "supplier_data_access" {
  name   = "put-s3-${var.data_feed}-${var.order_type}-policy"
  user   = aws_iam_user.supplier.name
  policy = data.aws_iam_policy_document.supplier_data_access.json
}

data "aws_iam_policy_document" "supplier_data_access" {
  statement {
    actions = [
      "s3:PutObject"
    ]

    resources = [
      var.landing_bucket_arn,
      "${var.landing_bucket_arn}/*",
    ]
  }
}

resource "aws_iam_access_key" "supplier" {
  user = aws_iam_user.supplier.name
}

resource "aws_secretsmanager_secret" "supplier" {
  name        = "iam-${aws_iam_user.supplier.name}"
  description = "IAM user access credentials for ${var.data_feed}-${var.order_type}"
  tags = merge(
    var.local_tags,
    { order_type = var.order_type },
    { data_feed = var.data_feed }
  )
}

resource "aws_secretsmanager_secret_version" "supplier" {
  secret_id     = aws_secretsmanager_secret.supplier.id
  secret_string = jsonencode({
    key    = aws_iam_access_key.supplier.id,
    secret = aws_iam_access_key.supplier.secret
  })
}
