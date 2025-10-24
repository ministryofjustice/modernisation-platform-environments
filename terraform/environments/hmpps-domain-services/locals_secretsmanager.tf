locals {

  domain_share_secret_principal_ids = {
    development = []
    test = [
      "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-development}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-test}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.core-shared-services-production}:role/ad-fixngo-ec2-nonlive-role",
      "arn:aws:iam::${module.environment.account_ids.nomis-development}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.nomis-test}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.nomis-data-hub-test}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.oasys-national-reporting-test}:role/EC2HmppsDomainSecretsRole",
    ]
    preproduction = []
    production = [
      "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-preproduction}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-production}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.corporate-staff-rostering-preproduction}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.corporate-staff-rostering-production}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.planetfm-preproduction}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.planetfm-production}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.core-shared-services-production}:role/ad-fixngo-ec2-live-role",
      "arn:aws:iam::${module.environment.account_ids.nomis-preproduction}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.nomis-production}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.nomis-data-hub-preproduction}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.nomis-data-hub-production}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.oasys-national-reporting-preproduction}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.oasys-national-reporting-production}:role/EC2HmppsDomainSecretsRole",
    ]
  }

  secretsmanager_secret_policies = {
    domain_read = {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
      ]
      principals = {
        type        = "AWS"
        identifiers = local.domain_share_secret_principal_ids[local.environment]
      }
      resources = ["*"]
    }
  }


  secretsmanager_secrets = {
    domain = {
      secrets = {
        shared-passwords = {
          description = "domain passwords shared with other accounts"
          policy = [
            local.secretsmanager_secret_policies.domain_read,
          ]
        }
      }
    }
    gfsl = {
      secrets = {
        planetfm-data-extract = {
          description = "configuration for GFSL planetFM data-extract script"
        }
      }
    }
  }
}
