locals {

  domain_share_secret_principal_ids = {
    development = []
    test = [
      "arn:aws:iam::${module.environment.account_ids.oasys-national-reporting-test}:policy/EC2SecretPolicy",
    ]
    preproduction = []
    production    = []
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

    bip = {
      secrets = {
        passwords = {}
      }
    }

    db = {
      secrets = {
        passwords = {
          description = "db passwords shared with other accounts"
          policy = [
            local.secretsmanager_secret_policies.domain_read,
          ]
        }
      }
    }

    db_oasys = {
      secrets = {
        passwords      = {}
        apex-passwords = {}
      }
    }

    db_bip = {
      secrets = {
        passwords     = {}
        bip-passwords = {}
      }
    }
  }
}
