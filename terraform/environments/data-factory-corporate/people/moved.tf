# Preserves the existing key and alias after replacing the registry KMS module with ./modules/kms-key.
moved {
  from = module.sherlock_kms_key.aws_kms_key.this[0]
  to   = module.sherlock_kms_key.aws_kms_key.this
}

moved {
  from = module.sherlock_kms_key.aws_kms_alias.this["sherlock-landing"]
  to   = module.sherlock_kms_key.aws_kms_alias.this
}

moved {
  from = module.sherlock_logging_bucket_cloudtrail
  to   = module.corp_people_logging_bucket
}
