terraform {
  required_version = ">= 1.7.0"
}

module "s3_bucket" {
  source = "git::ssh://git@github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/s3-bucket?ref=ea258ee2e63c433d8925ac9e751c44cb3b5225ed"

  bucket_prefix = "avature-landing"

    environment = "dev"

    tags = {
        Project = "Avature"
        Owner   = "CorporateDataEngineering"
        }

    kms_key_arn = module.kms_key.key_arn

    force_destroy = false

    lifecycle_rules = []    

}

module "kms_key" {
  source = "git::ssh://git@github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/kms?ref=1ee3641982b1849a8555fd6a096b3346a7ffb850"

  description = "KMS key for Avature Sherlock Test"
}