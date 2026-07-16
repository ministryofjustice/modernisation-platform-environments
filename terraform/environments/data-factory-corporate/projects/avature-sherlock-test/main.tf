
module "s3_bucket" {
  source = "git::ssh://git@github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/s3-bucket?ref=ben-dev"

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
  source = "git::ssh://git@github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/kms?ref=kms_module_1"

  description = "KMS key for Avature Sherlock Test"
}