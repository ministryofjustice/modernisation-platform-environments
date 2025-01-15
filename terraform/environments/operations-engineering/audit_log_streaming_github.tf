# tflint-ignore: terraform_required_providers
data "external" "build_lambdas" {
  program = [
    "bash", "-c",
    <<EOT
      cd .terraform/modules/github-cloudtrail-auditlog &&
      make all > /dev/null 2>&1 &&
      echo '{"status": "success"}'
    EOT
  ]
}

module "github-cloudtrail-auditlog" {
  source                          = "github.com/ministryofjustice/operations-engineering-cloudtrail-lake-github-audit-log-terraform-module?ref=299e5774acd66d86909e8a77017ee420ff79028e" # v1.0.0
  create_github_auditlog_s3bucket = true
  github_auditlog_s3bucket        = "github-audit-log-landing"
  cloudtrail_lake_channel_arn     = "arn:aws:cloudtrail:eu-west-2:211125434264:channel/810d471f-21e9-4552-b839-9e334f7fbe51"
  github_audit_allow_list         = ".*"

  # Ensure the module waits for Lambdas to be built
  depends_on = [data.external.build_lambdas]
}
