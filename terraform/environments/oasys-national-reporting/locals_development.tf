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

    patch_manager = {
      patch_schedules = {
        manual = "cron(00 21 31 2 ? *)" # 9pm 31 feb e.g. impossible date to allow for manual patching of otherwise enrolled instances
      }
      maintenance_window_duration = 2 # 4 for prod
      maintenance_window_cutoff   = 1 # 2 for prod
      patch_classifications = {
        # REDHAT_ENTERPRISE_LINUX = ["Security", "Bugfix"] # Linux Options=(Security,Bugfix,Enhancement,Recommended,Newpackage)
        WINDOWS = ["SecurityUpdates", "CriticalUpdates"]
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

