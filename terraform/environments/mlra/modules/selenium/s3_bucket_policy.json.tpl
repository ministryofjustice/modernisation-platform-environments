{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Principal": {
        "AWS": [
            "arn:aws:iam::${account_id}:role/${codebuild_role_name}"
        ]
      },
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::${s3_artifact_name}",
        "arn:aws:s3:::${s3_artifact_name}/*"
      ]
    }
  ]
}
