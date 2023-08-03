module "s3_bucket_archive" {
  count  = local.application_data.accounts[local.environment].existing_archive_bucket_name == "" ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_name = "laa-${local.application_name}-${local.environment}-archive-mp" # Added suffix -mp to the name as it must be unique from the existing bucket in LZ
  # bucket_prefix not used in case bucket name get referenced as part of EC2 AMIs
  replication_enabled = false
  versioning_enabled  = false
  force_destroy       = false
  lifecycle_rule = [
    {
      id      = "GlacierRule"
      enabled = "Enabled"

      transition = [
        {
          days          = 30
          storage_class = "GLACIER"
        }
      ]
    }
  ]

  tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-archive" }
  )

}

resource "aws_s3_object" "object_oam" {
  bucket = "laa-${local.application_name}-${local.environment}-archive-mp"
  key = "oam1/"
}
resource "aws_s3_object" "object_oam2" {
  count  = contains(["development", "testing"], local.environment) ? 0 : 1
  bucket = "laa-${local.application_name}-${local.environment}-archive-mp"
  key = "oam2/"
}
resource "aws_s3_object" "object_idm" {
  bucket = "laa-${local.application_name}-${local.environment}-archive-mp"
  key = "idm1/"
}
resource "aws_s3_object" "object_idm2" {
  count  = contains(["development", "testing"], local.environment) ? 0 : 1
  bucket = "laa-${local.application_name}-${local.environment}-archive-mp"
  key = "idm2/"
}
resource "aws_s3_object" "object_oim" {
  bucket = "laa-${local.application_name}-${local.environment}-archive-mp"
  key = "oim1/"
}
resource "aws_s3_object" "object_oim2" {
  count  = contains(["development", "testing"], local.environment) ? 0 : 1
  bucket = "laa-${local.application_name}-${local.environment}-archive-mp"
  key = "oim2/"
}

resource "aws_s3_object" "object_ohs" {
  bucket = "laa-${local.application_name}-${local.environment}-archive-mp"
  key = "ohs1/"
}

resource "aws_s3_object" "object_ohs2" {
  count  = contains(["development", "testing"], local.environment) ? 0 : 1
  bucket = "laa-${local.application_name}-${local.environment}-archive-mp"
  key = "ohs2/"
}