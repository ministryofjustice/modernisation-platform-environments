locals {
  log_bucket = "s3-bucket-access-logging"
}

## Ensure that the s3 log bucket exists before attempting to create any other buckets.
module "s3-log" {
  source = "./modules/s3"

  environment_name = local.environment_name

  bucket_name = [local.log_bucket]

  project_name = local.project_name

  tags = local.tags

 # ownership_controls = "BucketOwnerEnforced"
}

module "s3" {
  source = "./modules/s3"

  environment_name = local.environment_name

  log_bucket = "${var.environment_name}-${local.log_bucket}"

  bucket_name  = ["redshift-yjb-reporting", "install-files"]
 
  archive_bucket_name  = ["s3-bucket-access-logging", "redshift-yjb-reporting",  
                          "aws-security-hub-findings-ex-hublog", "tf-webops-config-service", "tableau-alb-logs", "yjaf-ext-external-logs",
                          "yjaf-int-internal-logs", "cloudfront-logs", "cloudtrail-logs", "guardduty-to-fallanx-archive", "tableau-backups"
                         ]

  transfer_bucket_name  = ["bands", "bedunlock", "cmm", "cms", "incident", "mis", "reporting", "yjsm-artefact",  "yjsm", "transfer"]
 
                   
  project_name = local.project_name

  allow_replication = local.application_data.accounts[local.environment].allow_s3_replication
  s3_source_account = local.application_data.accounts[local.environment].source_account

  tags = local.tags

  depends_on = [ module.s3-log ]
}
