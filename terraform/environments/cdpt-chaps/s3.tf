resource "aws_s3_bucket" "data_protection_keys" {
  bucket = "chapsdotnet-data-protection-keys"

  tags = {
    Name        = "chapsdotnet-data-protection-keys"
    Environment = "production"
  }
}

resource "aws_s3_bucket_policy" "data_protection_policy" {
  bucket = aws_s3_bucket.data_protection_keys.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = ["s3:GetObject", "s3.PutObject"],
        Resource = "${aws_s3_bucket.data_protection_keys.arn}/*"
      }
    ]
  })
}