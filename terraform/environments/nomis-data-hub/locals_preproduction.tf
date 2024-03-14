locals {
  preproduction_config = {
    baseline_secretsmanager_secrets = {
      "/ndh/pp" = local.ndh_secretsmanager_secrets
    }

    baseline_iam_policies = {
      Ec2ppPolicy = {
        description = "Permissions required for PP EC2s"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ndh/pp/*",
            ]
          }
        ]
      }
    }

    baseline_route53_zones = {
      "preproduction.ndh.nomis.service.justice.gov.uk" = {
        records = []
      }
    }
  }
}
