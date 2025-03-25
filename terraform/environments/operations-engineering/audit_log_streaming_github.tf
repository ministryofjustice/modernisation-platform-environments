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

data "aws_kms_key" "key" {
  key_id = "alias/GitHubCloudTrailOpenEvent"
}

resource "aws_iam_policy" "github_audit_log_write_policy" {
  name = "github-audit-log-write-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${module.github-cloudtrail-auditlog.github_auditlog_s3bucket}/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Encrypt",
          "kms:ReEncrypt",
          "kms:GenerateDataKey"
        ],
        "Resource" : data.aws_kms_key.key.arn
      }
    ]
  })
}

resource "aws_iam_role" "github_audit_log_role" {
  name = "github-audit-log-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "oidc-configuration.audit-log.githubusercontent.com:aud" = "sts.amazonaws.com",
            "oidc-configuration.audit-log.githubusercontent.com:sub" = "https://github.com/ministry-of-justice-uk"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "github_policy_attachment" {
  name       = "github-audit-log-policy-attachment"
  policy_arn = aws_iam_policy.github_audit_log_write_policy.arn
  roles      = [aws_iam_role.github_audit_log_role.name]
}
