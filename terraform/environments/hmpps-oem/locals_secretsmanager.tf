locals {

  oem_share_secret_principal_ids = {
    development = [
      "arn:aws:iam::${module.environment.account_ids.corporate-staff-rostering-development}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-core-development}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-core-development}:role/modernisation-platform-oidc-cicd",
      "arn:aws:iam::${module.environment.account_ids.delius-mis-development}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-mis-development}:role/modernisation-platform-oidc-cicd",
      "arn:aws:iam::${module.environment.account_ids.nomis-combined-reporting-development}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.nomis-development}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.oasys-development}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-iaps-development}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-iaps-development}:role/modernisation-platform-oidc-cicd",
    ]
    test = [
      "arn:aws:iam::${module.environment.account_ids.corporate-staff-rostering-test}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-core-test}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-core-test}:role/modernisation-platform-oidc-cicd",
      "arn:aws:iam::${module.environment.account_ids.nomis-combined-reporting-test}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.nomis-test}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.oasys-test}:role/EC2OracleEnterpriseManagementSecretsRole",
    ]
    preproduction = [
      "arn:aws:iam::${module.environment.account_ids.corporate-staff-rostering-preproduction}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-core-preproduction}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-core-preproduction}:role/modernisation-platform-oidc-cicd",
      "arn:aws:iam::${module.environment.account_ids.delius-mis-preproduction}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-mis-preproduction}:role/modernisation-platform-oidc-cicd",
      "arn:aws:iam::${module.environment.account_ids.nomis-combined-reporting-preproduction}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.nomis-preproduction}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.oasys-preproduction}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-iaps-preproduction}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-iaps-preproduction}:role/modernisation-platform-oidc-cicd",
    ]
    production = [
      "arn:aws:iam::${module.environment.account_ids.corporate-staff-rostering-production}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.nomis-combined-reporting-production}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.nomis-production}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.oasys-production}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-iaps-production}:role/EC2OracleEnterpriseManagementSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.delius-iaps-production}:role/modernisation-platform-oidc-cicd",
    ]
  }

  secretsmanager_secret_policies = {
    write = {
      effect = "Allow"
      actions = [
        "secretsmanager:PutSecretValue",
      ]
      principals = {
        type        = "AWS"
        identifiers = ["hmpps-oem-${local.environment}"]
      }
      resources = ["*"]
    }
    read = {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
      ]
      principals = {
        type        = "AWS"
        identifiers = local.oem_share_secret_principal_ids[local.environment]
      }
      resources = ["*"]
    }
  }

  secretsmanager_secrets = {
    oem = {
      secrets = {
        passwords = {
          description = "passwords only accessible by OEM EC2"
          policy = [
            local.secretsmanager_secret_policies.write # this isn't strictly needed but is added to clear a previous policy
          ]
        }
        shared-passwords = {
          description = "passwords shared with other accounts"
          policy = [
            local.secretsmanager_secret_policies.read,
            local.secretsmanager_secret_policies.write,
          ]
        }
      }
    }
  }
}
