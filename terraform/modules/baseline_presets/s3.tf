locals {

  s3_iam_policies = {
    EC2S3BucketReadOnlyPolicy = [
      {
        effect = "Allow"
        actions = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
      }
    ]
    EC2S3BucketWriteAccessPolicy = [
      {
        effect = "Allow"
        actions = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
        ]
      }
    ]
    EC2S3BucketWriteAndDeleteAccessPolicy = [
      {
        effect = "Allow"
        actions = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
      }
    ]
  }
}
