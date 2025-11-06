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

  bucket_name = ["install-files", "application-memory-heap-dump", "tableau-server-install-files"]

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
  #only in development or prod
  count  = local.environment == "development" || local.environment == "preproduction" ? 1 : 0
  source = "./modules/s3"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags
  bucket_name  = ["taskbuilder"]

  add_log_policy = false #we are not recieving logs into this bucket

}

#allow access from circleci to taskbuilder bucket
resource "aws_s3_bucket_policy" "taskbuilder" {
  count = local.environment == "development" || local.environment == "preproduction" ? 1 : 0

  bucket = module.s3-taskbuilder[0].aws_s3_bucket_id["taskbuilder"].id


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowListBucket"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${local.environment_management.account_ids["youth-justice-app-framework-development"]}:role/circleci_iam_role",
            "arn:aws:iam::${local.environment_management.account_ids["youth-justice-app-framework-test"]}:role/circleci_iam_role",
            "arn:aws:iam::${local.environment_management.account_ids["youth-justice-app-framework-preproduction"]}:role/circleci_iam_role",
            "arn:aws:iam::${local.environment_management.account_ids["youth-justice-app-framework-production"]}:role/circleci_iam_role"
          ]
        }
        Action   = "s3:ListBucket"
        Resource = module.s3-taskbuilder[0].aws_s3_bucket["taskbuilder"].arn
      },
      {
        Sid    = "AllowGetObject"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${local.environment_management.account_ids["youth-justice-app-framework-development"]}:role/circleci_iam_role",
            "arn:aws:iam::${local.environment_management.account_ids["youth-justice-app-framework-test"]}:role/circleci_iam_role",
            "arn:aws:iam::${local.environment_management.account_ids["youth-justice-app-framework-preproduction"]}:role/circleci_iam_role",
            "arn:aws:iam::${local.environment_management.account_ids["youth-justice-app-framework-production"]}:role/circleci_iam_role"
          ]
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3-taskbuilder[0].aws_s3_bucket["taskbuilder"].arn}/*"
      }
    ]
  })
}

module "s3-sbom" {
  source = "./modules/s3"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags
  bucket_name  = ["application-sbom"]

  add_log_policy = false

}

# Bucket policy allowing Inspector to put objects
resource "aws_s3_bucket_policy" "sbom" {
  bucket     = module.s3-sbom.aws_s3_bucket_id["application-sbom"].id
  policy     = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Effect":"Allow",
      "Principal":{"Service":"inspector2.amazonaws.com"},
      "Action":"s3:PutObject",
      "Resource":"${module.s3-sbom.aws_s3_bucket["application-sbom"].arn}/*"
    }
  ]
}
EOF
  depends_on = [module.s3-sbom]
}

module "s3-certs" {
  #only in development or prod
  count  = local.environment == "development" || local.environment == "preproduction" ? 1 : 0
  source = "./modules/s3"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags
  bucket_name  = ["certs"]

  add_log_policy = true

}


