module "github-cloudtrail-auditlog" {
  source                          = "github.com/ministryofjustice/operations-engineering-cloudtrail-lake-github-audit-log-terraform-module?ref=main"
  create_github_auditlog_s3bucket = true
  github_auditlog_s3bucket        = "github-audit-log-landing"
  cloudtrail_lake_channel_arn     = "arn:aws:cloudtrail:eu-west-2:211125434264:channel/810d471f-21e9-4552-b839-9e334f7fbe51"
  github_audit_allow_list         = ".*"
}
