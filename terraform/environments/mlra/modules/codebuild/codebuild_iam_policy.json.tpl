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
        "logs:PutLogEvents",
        "ecr:GetAuthorizationToken"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "arn:aws:ecr:eu-west-2:${core_shared_services_production_account_id}:repository/${app_name}-ecr-repo",
        "arn:aws:ecr:eu-west-2:${account_id}:repository/${app_name}-local-ecr"
      ],
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:GetAuthorizationToken"
      ]
    }
  ]
}