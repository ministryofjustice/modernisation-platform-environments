#### This file can be used to store data specific to the member account ####
data "aws_availability_zones" "available" {}

data "aws_iam_policy_document" "s3_bold_egress_s3_policy" {
  statement {
    sid    = "ReplicationPermissions"
    effect = "Allow"
    principals { 
      type = "AWS"
      identifiers = ["arn:aws:iam::593291632749:role/service-role/source-account-IAM-role"]
    }
    actions = [
      "s3:ReplicateDelete",
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = ["*"]
    # resources = module.bold_egress_bucket.arn
  }



}