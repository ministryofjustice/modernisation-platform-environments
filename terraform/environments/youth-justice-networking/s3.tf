module "s3-bucket" {
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399" #v9.0.0
  bucket_prefix       = "juniper-historical"
  versioning_enabled  = true
  ownership_controls  = "BucketOwnerEnforced"
  bucket_policy       = [data.aws_iam_policy_document.bucket_policy.json]
  force_destroy       = true
  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }
  tags = local.tags
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "PermissionsOnObjectsAndBuckets"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::597593175223:role/JuniperRoleS3Replication"]
    }

    actions = [
      "s3:List*",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning",
      "s3:ReplicateDelete",
      "s3:ReplicateObject",
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${module.s3-bucket.bucket.id}",
      "arn:aws:s3:::${module.s3-bucket.bucket.id}/*"
    ]
  }

  statement {
    sid    = "PermissionToOverrideBucketOwner"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::597593175223:role/JuniperRoleS3Replication"]
    }

    actions = ["s3:ObjectOwnerOverrideToBucketOwner"]

    resources = ["arn:aws:s3:::${module.s3-bucket.bucket.id}/*"]
  }
}