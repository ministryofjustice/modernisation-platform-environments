# Terraform import blocks for resources that exist in AWS but are missing from state.
# Fill in ALL placeholder values for ALL four environments before pushing.
# Once the pipeline has successfully applied, delete this file entirely.
#
# How to find each value (run in each environment's AWS account):
#
#   iam_access_key_id:
#     AWS Console → Secrets Manager → postfix/app/APP_DATA_MIGRATION_SMTP_USER → Retrieve secret value
#     The value is the access key ID (starts with AKIA...)
#
#   route53_zone_id + route53_zone_name:
#     AWS Console → Route53 → Hosted zones → find the laa-<env>.modernisation-platform... zone
#     Copy the Hosted Zone ID (without /hostedzone/ prefix) and the zone name (without trailing dot)
#
#   smtp_password_secret_arn:
#     AWS Console → Secrets Manager → postfix/app/APP_DATA_MIGRATION_SMTP_PASSWORD → copy the Secret ARN
#
#   smtp_password_version_id:
#     AWS Console → Secrets Manager → postfix/app/APP_DATA_MIGRATION_SMTP_PASSWORD
#     → Secret value tab → Version ID shown below the value
#
#   EC2 instance (test/preproduction/production only):
#     If the smtp EC2 instance already exists in AWS for that environment, add a one-off import block:
#       import {
#         to = aws_instance.smtp
#         id = "i-xxxxxxxxxxxxxxxxx"
#       }
#     Development has no instance — Terraform will create it fresh.

locals {
  smtp_import_ids = {
    development = {
      iam_access_key_id        = "AKIAQMEY6GSHNDPEUVWY"
      route53_zone_id          = "Z0032141ZAYV8DVWNDDC"
      route53_zone_name        = "laa-development.modernisation-platform.service.justice.gov.uk"
      smtp_password_secret_arn = "arn:aws:secretsmanager:eu-west-2:688567291430:secret:postfix/app/APP_DATA_MIGRATION_SMTP_PASSWORD-1vOeLY"
      smtp_password_version_id = "3ca3977c-0db0-4f9c-a8cb-ca1fa034003d"
    }
    test = {
      iam_access_key_id        = "AKIA2AUOPBYTMYM46K6A"
      route53_zone_id          = "Z0321080TDDRIM16INGC"
      route53_zone_name        = "laa-test.modernisation-platform.service.justice.gov.uk"
      smtp_password_secret_arn = "arn:aws:secretsmanager:eu-west-2:688567291430:secret:postfix/app/APP_DATA_MIGRATION_SMTP_PASSWORD-1vOeLY"
      smtp_password_version_id = "terraform-20250117124656938900000001"
    }
    preproduction = {
      iam_access_key_id        = "AKIA4SZHNXXSMCO6OBKO"
      route53_zone_id          = "Z00513657KO1LCLQ89Z9"
      route53_zone_name        = "laa-preproduction.modernisation-platform.service.justice.gov.uk"
      smtp_password_secret_arn = "arn:aws:secretsmanager:eu-west-2:864981728740:secret:postfix/app/APP_DATA_MIGRATION_SMTP_PASSWORD-lDnfXD"
      smtp_password_version_id = "terraform-20250122121009851200000008"
    }
    production = {
      iam_access_key_id        = "AKIA4WJPWYAR45A6OW4S"
      route53_zone_id          = "Z05810263DZPHQBFPPJAC"
      route53_zone_name        = "laa-production.modernisation-platform.service.justice.gov.uk"
      smtp_password_secret_arn = "arn:aws:secretsmanager:eu-west-2:872515289123:secret:postfix/app/APP_DATA_MIGRATION_SMTP_PASSWORD-PCF1qU"
      smtp_password_version_id = "terraform-20250127102330413700000008"
    }
  }
}

# IAM User — name is derived from config, no placeholder needed
import {
  to = aws_iam_user.smtp
  id = "${local.application_name}-${local.application_data.accounts[local.environment].env_short}-user"
}

# IAM Access Key — ID must be retrieved from Secrets Manager per environment
import {
  to = aws_iam_access_key.smtp
  id = local.smtp_import_ids[local.environment].iam_access_key_id
}

# IAM User Policy — name is derived from config, no placeholder needed
import {
  to = aws_iam_user_policy.smtp_user
  id = "${local.application_name}-${local.application_data.accounts[local.environment].env_short}-user:AmazonSesSendingAccess"
}

# Route53 Record — format is ZONE_ID_RECORD_NAME_TYPE
import {
  to = aws_route53_record.smtp
  id = "${local.smtp_import_ids[local.environment].route53_zone_id}_laa-mail.${local.smtp_import_ids[local.environment].route53_zone_name}_A"
}

# Secrets Manager Secrets — names are the same in every environment account
import {
  to = aws_secretsmanager_secret.smtp_password
  id = "postfix/app/APP_DATA_MIGRATION_SMTP_PASSWORD"
}

import {
  to = aws_secretsmanager_secret.smtp_sesrsa
  id = "postfix/app/SESRSA"
}

import {
  to = aws_secretsmanager_secret.smtp_sesrsap
  id = "postfix/app/SESRSAP"
}

# Secret Version — format is SECRET_ARN|VERSION_ID, both differ per environment account
import {
  to = aws_secretsmanager_secret_version.smtp_password
  id = "${local.smtp_import_ids[local.environment].smtp_password_secret_arn}|${local.smtp_import_ids[local.environment].smtp_password_version_id}"
}