locals {
  log_bucket = "s3-bucket-access-logging"
}

## Ensure that the s3 log bucket exists before attempting to create any other buckets.
module "s3-log" {
  source = "./modules/s3"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags
  bucket_name  = [local.log_bucket]

  add_log_policy = true

  # ownership_controls = "BucketOwnerEnforced"
}

module "s3" {
  source = "./modules/s3"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags

  log_bucket = "${local.environment_name}-${local.log_bucket}"

  bucket_name = ["install-files"]

  archive_bucket_name = ["s3-bucket-access-logging", "redshift-yjb-reporting", "tf-webops-config-service", "tableau-alb-logs", "yjaf-ext-external-logs",
    "yjaf-int-internal-logs", "cloudfront-logs", "cloudtrail-logs", "guardduty-to-fallanx-archive", "tableau-backups",
    "aws-glue-assets", "cloudtrail-logs"
  ]

  transfer_bucket_name = ["bands", "bedunlock", "cmm", "cms", "incident", "mis", "reporting", "yjsm-artefact", "yjsm", "transfer",
  "historical-infrastructure", "historical-apps"]

  allow_replication = local.application_data.accounts[local.environment].allow_s3_replication
  s3_source_account = local.application_data.accounts[local.environment].source_account

  depends_on = [module.s3-log]
}

module "s3-taskbuilder" {
  #only in prod
  count  = local.environment == "development" ? 1 : 0
  source = "./modules/s3"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags
  bucket_name  = ["taskbuilder"]

  add_log_policy = true

}

module "s3-sbom" {
  #only in prod
  count  = local.environment == "development" ? 1 : 0
  source = "./modules/s3"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags
  bucket_name  = ["application-sbom"]

  add_log_policy = true

}
