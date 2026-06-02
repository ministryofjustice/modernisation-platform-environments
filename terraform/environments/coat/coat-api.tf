resource "aws_iam_role" "coat_api_cross_account_role" {
  name = "coat-api-cross-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = [
            data.aws_iam_role.moj_mp_dev_role[0].arn
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "athena_full_access" {
  role       = aws_iam_role.coat_api_cross_account_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.coat_api_cross_account_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "s3_write_access" {
  role       = aws_iam_role.coat_api_cross_account_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}