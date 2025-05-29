module "github_audit_log_athena_results" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=474f27a3f9bf542a8826c76fb049cc84b5cf136f" # v8.2.1

  bucket_prefix = "github-audit-log-athena-results-"
  providers = {
    aws.bucket-replication = aws
  }
  tags = local.tags
}

resource "aws_athena_workgroup" "github_auditlog" {
  name = "github-auditlog-wg"

  configuration {
    result_configuration {
      output_location = "s3://${module.github_audit_log_athena_results.bucket.id}/results/"
    }

    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    bytes_scanned_cutoff_per_query     = "1000000000" # 1GB, adjust as needed
    requester_pays_enabled             = false
  }

  state = "ENABLED"

  tags = local.tags
}

