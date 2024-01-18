locals {

  domain_share_secret_principal_ids = {
    development = []
    test = [
      "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-development}:role/EC2HmppsDomainSecretsRole",
      "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-test}:role/EC2HmppsDomainSecretsRole",
    ]
    preproduction = []
    production = [
      # "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-preproduction}:role/EC2HmppsDomainSecretsRole",
      # "arn:aws:iam::${module.environment.account_ids.hmpps-domain-services-production}:role/EC2HmppsDomainSecretsRole",
    ]
  }

  domain_secret_policy_read = {
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

  domain_secretsmanager_secrets = {
    secrets = {
      passwords = {
        description = "domain passwords only accessible by this account"
      }
      shared-passwords = {
        description = "domain passwords shared with other accounts"
        policy = [
          local.domain_secret_policy_read,
        ]
      }
      shared-config = {
        description = "domain related config shared with other accounts"
        policy = [
          local.domain_secret_policy_read,
        ]
      }
    }
  }
}
