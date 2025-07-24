locals {

  baseline_presets_development = {
    options = {
      # disabling some features in development as the environment gets nuked
      cloudwatch_metric_oam_links_ssm_parameters = []
      cloudwatch_metric_oam_links                = []
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    iam_policies = {
      Ec2SecretPolicy = {
        description = "Permissions required for secret value access by instances"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/sap/bods/dev/*",
              "arn:aws:secretsmanager:*:*:secret:/sap/bip/dev/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*",
            ]
          }
        ]
      }
    }

    route53_zones = {
      "development.reporting.oasys.service.justice.gov.uk" = {}
    }

    secretsmanager_secrets = {
      "/sap/bods/dev"            = local.secretsmanager_secrets.bods
      "/sap/bip/dev"             = local.secretsmanager_secrets.bip
      "/oracle/database/TESTSYS" = local.secretsmanager_secrets.db
      "/oracle/database/TESTAUD" = local.secretsmanager_secrets.db
    }
  }
}