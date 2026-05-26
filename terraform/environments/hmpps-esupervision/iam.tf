# find managed policy for read-only rekognition access
data "aws_iam_policy" "rekognition_read" {
  name = "AmazonRekognitionReadOnlyAccess"
}

# additional rekognition actions not covered by the read-only managed policy
data "aws_iam_policy_document" "rekognition_liveness" {
  statement {
    sid    = "RekognitionLiveness"
    effect = "Allow"
    actions = [
      "rekognition:CreateFaceLivenessSession",
      "rekognition:StartFaceLivenessSession",
      "rekognition:GetFaceLivenessSessionResults",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "rekognition_liveness" {
  name   = "rekognition-liveness"
  policy = data.aws_iam_policy_document.rekognition_liveness.json
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

# create rekognition role and attach rekognition policies
resource "aws_iam_role" "rekognition_role" {
  name               = "rekognition-role"
  assume_role_policy = data.aws_iam_policy_document.assume_rekognition_role_policy.json
}

resource "aws_iam_role_policy_attachment" "rekognition_rekognition" {
  role       = aws_iam_role.rekognition_role.name
  policy_arn = data.aws_iam_policy.rekognition_read.arn
}

resource "aws_iam_role_policy_attachment" "rekognition_liveness" {
  role       = aws_iam_role.rekognition_role.name
  policy_arn = aws_iam_policy.rekognition_liveness.arn
}

# Policy to allow Rekognition role to read from Cloud Platform S3 buckets
# The Cloud Platform buckets also need a bucket policy granting this role access
data "aws_iam_policy_document" "cloud_platform_s3_read" {
  statement {
    sid    = "CloudPlatformBucketRead"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "arn:aws:s3:::cloud-platform-*/*"
    ]
  }
}

resource "aws_iam_policy" "cloud_platform_s3_read_policy" {
  name   = "rekognition-cloud-platform-s3-read"
  policy = data.aws_iam_policy_document.cloud_platform_s3_read.json
}

resource "aws_iam_role_policy_attachment" "rekognition_cloud_platform_s3" {
  role       = aws_iam_role.rekognition_role.name
  policy_arn = aws_iam_policy.cloud_platform_s3_read_policy.arn
}
