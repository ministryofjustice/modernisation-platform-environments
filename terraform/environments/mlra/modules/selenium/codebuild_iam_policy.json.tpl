{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:GetObjectVersion",
        "s3:GetBucketPolicy",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${s3_report_bucket_name}",
        "arn:aws:s3:::${s3_report_bucket_name}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    }

  ]
}
