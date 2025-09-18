# policy document for allowing access to rekognition s3 bucket
data "aws_iam_policy_document" "rekognition_s3_policy_document" {
  statement {
    sid    = "LocateUserBuckets"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation"
    ]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    sid       = "RekognitionBucketList"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.rekognition_bucket.arn]
  }

  statement {
    sid    = "RekognitionBucketCRUDOperations"
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
  name   = "rekognition_uploads_bucket_access"
  policy = data.aws_iam_policy_document.rekognition_s3_policy_document.json
}

# find managed policy for read-only rekognition access
data "aws_iam_policy" "rekognition_read" {
  name = "AmazonRekognitionReadOnlyAccess"
}

# grant configured principals permission to assume the rekognition role
data "aws_iam_policy_document" "assume_rekognition_role_policy" {
  dynamic "statement" {
    for_each = local.allowed_assume_role_principals
    iterator = principal

    content {
      sid    = "Allow${principal.key}Assume"
      effect = "Allow"
      principals {
        identifiers = [principal.value]
        type        = "AWS"
      }
      actions = ["sts:AssumeRole"]
    }
  }
}

# create rekognition role and attach s3 and rekognition policies
resource "aws_iam_role" "rekognition_role" {
  name               = "rekognition-role"
  assume_role_policy = data.aws_iam_policy_document.assume_rekognition_role_policy.json
}

resource "aws_iam_role_policy_attachment" "rekognition_s3" {
  role       = aws_iam_role.rekognition_role.name
  policy_arn = aws_iam_policy.rekognition_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "rekognition_rekognition" {
  role       = aws_iam_role.rekognition_role.name
  policy_arn = data.aws_iam_policy.rekognition_read.arn
}
