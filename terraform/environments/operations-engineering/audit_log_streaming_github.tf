module "github-cloudtrail-auditlog" {
  source                          = "github.com/ministryofjustice/operations-engineering-cloudtrail-lake-github-audit-log-terraform-module?ref=main"
  create_github_auditlog_s3bucket = true
  github_auditlog_s3bucket        = "github-audit-log-landing"
  cloudtrail_lake_channel_arn     = aws_cloudtrail_channel.github_channel.arn
  github_audit_allow_list         = ".*"
}

resource "aws_cloudtrail_event_data_store" "github_audit_logs" {
  name                           = "github-audit-logs-store"
  retention_period               = 90
  termination_protection_enabled = true

  advanced_event_selector {
    name = "GitHubAuditLogs"
    field_selector {
      field  = "eventSource"
      equals = ["GitHub"]
    }
  }
}

resource "aws_cloudtrail_channel" "github_channel" {
  name                    = "github-audit-log-channel"
  source                  = "Github"
  destinations            = [aws_cloudtrail_event_data_store.github_audit_logs.arn]
  advanced_event_selector = aws_cloudtrail_event_data_store.github_audit_logs.advanced_event_selector
}
