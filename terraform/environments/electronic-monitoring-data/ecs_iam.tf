# -----------------------
# Dagster IAM perms
# -----------------------

resource "aws_iam_role" "dagster_role" {
  name = "dagster_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "dagster_policy" {
  name = "dagster_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ]
      Effect   = "Allow"
      Resource = [module.dagster-bucket.bucket_arn, "${module.dagster-bucket.bucket_arn}/*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dagster_attach" {
  role       = aws_iam_role.dagster_role.name
  policy_arn = aws_iam_policy.dagster_policy.arn
}