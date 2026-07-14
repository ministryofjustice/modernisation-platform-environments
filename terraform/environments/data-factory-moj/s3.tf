module "s3_bucket" {
  # source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=af0286ff37a66c2b79faf360e6e2663744b8e5b5" # v5.13.0
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=c60d60b9b31ee2544e34adc3b6e82db5f2b95672"
  
  bucket_name      = "intermediate-salad-aisle-rehearsal"
  bucket_namespace = "account-regional"

  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    # Leave this provider block in even if you are not using replication
    aws.bucket-replication = aws
  }

  sse_algorithm = "AES256"

  tags = local.tags
}