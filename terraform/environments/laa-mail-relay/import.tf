# Import blocks for resources that exist in AWS dev but are missing from dev state.
#
# IMPORTANT — 2-step process required:
#   Step 1: Apply dev pipeline with these import blocks in place.
#   Step 2: Remove this file, then push again so test/preprod/prod can apply.
#           (test/preprod/prod already have these resources in state — import blocks
#            targeting already-in-state resources will error for those environments.)
#
# Route53 record — must use a literal string ID; locals/variables are not allowed
# in import block id fields (Terraform constraint). One block per environment:
#
#   Format: ZONE_ID_RECORD_NAME_TYPE
#   dev zone:     Z0032141ZAYV8DVWNDDC
#   test zone:    Z0321080TDDRIM16INGC
#   preprod zone: Z00513657KO1LCLQ89Z9
#   prod zone:    Z05810263DZPHQBFPPJAC

import {
  to = aws_route53_record.smtp
  id = "Z0032141ZAYV8DVWNDDC_laa-mail.laa-development.modernisation-platform.service.justice.gov.uk_A"
}

# Secrets — same name in all environments; already in state for test/preprod/prod.
# Remove these 3 blocks before applying test/preprod/prod.

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