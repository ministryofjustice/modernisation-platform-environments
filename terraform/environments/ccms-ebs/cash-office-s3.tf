resource "aws_iam_user" "aw2" {
  name = "andy.welsh.test1"
}

resource "aws_iam_user" "aw2" {
  name = "andy.welsh.test2"
}


resource "aws_iam_role" "role" {
  name = "cash_office_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_trust_policy.json
}

#--Data
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    resources = [
      aws_iam_role.role.arn
    ]
  }
}

data "aws_iam_policy_document" "assume_role_trust_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [
        aws_iam_user.aw1.arn,
        aws_iam_user.aw2.arn
      ]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["10.200.16.0/20"] #--Add another CIDR to this list to control access
    }
  }
}

data "aws_iam_policy_document" "s3" {
  statement {
    sid    = "AllowLimitedS3"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::laa-ccms-inbound-development-mp/*" #--Param needed
    ]
  }

  statement {
    sid    = "AllowListBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::laa-ccms-inbound-development-mp" #--Param needed
    ]
  }
}

#--Grant users role assumption permissions, turn this in to a loop
resource "aws_iam_user_policy" "aw1_assume_policy" {
  name = "aw1_assume_role"
  user = aws_iam_user.aw1.name
  policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_user_policy" "aw2_assume_policy" {
  name = "aw2_assume_role"
  user = aws_iam_user.aw2.name
  policy = data.aws_iam_policy_document.assume_role_policy.json
}

#--Attach S3 policy to role
resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.s3.arn
}
