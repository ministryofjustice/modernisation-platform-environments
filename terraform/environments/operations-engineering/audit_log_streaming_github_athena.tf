module "github_audit_log_athena_results" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=474f27a3f9bf542a8826c76fb049cc84b5cf136f" # v8.2.1

  bucket_prefix = "github-audit-log-athena-results-"
  providers = {
    aws.bucket-replication = aws
  }
  tags = local.tags
}
