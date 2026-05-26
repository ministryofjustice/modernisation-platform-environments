resource "aws_s3_bucket" "replica" {
  count = local.environment == "preproduction" ? 1 : 0

  bucket = "edw-19c-preprod-replica-bucket"

  tags = {
    Name        = "edw-19c-preprod-replica-bucket"
    Environment = "preproduction"
    Purpose     = "s3-replication-destination"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  count  = local.environment == "preproduction" ? 1 : 0
  bucket = aws_s3_bucket.replica[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "replica" {
  count  = local.environment == "preproduction" ? 1 : 0
  bucket = aws_s3_bucket.replica[0].id


  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "replica" {
  count  = local.environment == "preproduction" ? 1 : 0
  bucket = aws_s3_bucket.replica[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowReplicationFromRemoteBucketRole",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::258180561819:role/edw-upgrade-edw-19c-preproduction-replication"
        },
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ],
        Resource = "${aws_s3_bucket.replica[0].arn}/*"
      },
      {
        Sid    = "AllowReplicationBucketLevelAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::258180561819:role/edw-upgrade-edw-19c-preproduction-replication"
        },
        Action = [
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning"
        ],
        Resource = aws_s3_bucket.replica[0].arn
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_versioning.replica
  ]
}
