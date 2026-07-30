module "sherlock_landing_bucket" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-moj-data-factory-modules.git//modules/s3-bucket?ref=313b46a604dc6aaee1d7309990388c6687272b6e"

  bucket_prefix = "landing-sherlock"
  kms_key_arn   = module.sherlock_kms_key.key_arn
  enable_malware_protection = true
  tags = {
    Environment = terraform.workspace
    Application = "data-factory-corporate"
    Component   = "people"
    Infrastructure = "sherlock-landing-bucket"
  }
}

module "sherlock_kms_key" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git//?ref=496d8bd559afebb43b78af0034ec74d8b32378ca"

  aliases = ["sherlock-landing"]
}