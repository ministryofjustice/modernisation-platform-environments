resource "aws_iam_user" "rekognition_user" {
  name = "rekognition"
}

data "aws_iam_policy_document" "rekognition_s3_policy_document" {
  statement {
    sid = "LocateUserBuckets"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation"
    ]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    sid = "RekognitionBucketList"
    effect = "Allow"
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.rekognition_bucket.arn]
  }

  statement {
    sid = "RekognitionBucketCRUDOperations"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.rekognition_bucket.arn}/*"]
  }
}

resource "aws_iam_policy" "rekognition_s3_policy" {
  name = "rekognition_uploads_bucket_access"
  policy = data.aws_iam_policy_document.rekognition_s3_policy_document.json
}

data "aws_iam_policy" "rekognition_read" {
  name = "AmazonRekognitionReadOnlyAccess"
}

resource "aws_iam_user_policy_attachment" "rekognition_rekognition" {
  user = aws_iam_user.rekognition_user.name
  policy_arn = data.aws_iam_policy.rekognition_read.arn
}

resource "aws_iam_user_policy_attachment" "rekognition_s3" {
  user = aws_iam_user.rekognition_user.name
  policy_arn = aws_iam_policy.rekognition_s3_policy.arn
}

# access key
resource "aws_iam_access_key" "rekognition_user_access_key" {
  user = aws_iam_user.rekognition_user.name
}

# store access key secret
resource "aws_secretsmanager_secret" "rekognition_user_access_key" {
  name = "rekognition-user-access-key"
}

resource "aws_secretsmanager_secret_version" "rekognition_user_access_key_value" {
  secret_id     = aws_secretsmanager_secret.rekognition_user_access_key.id
  secret_string = jsonencode({
    aws_access_key_id = aws_iam_access_key.rekognition_user_access_key.id
    aws_secret_access_key = aws_iam_access_key.rekognition_user_access_key.secret
  })
}