locals {

  domain_share_secret_principal_ids = {
    development = []
    test = [
      "arn:aws:iam::${module.environment.account_ids.oasys-national-reporting-test}:policy/EC2SecretPolicy",
    ]
    preproduction = []
    production    = []
  }

  secretsmanager_secrets = {

    bip = {
      secrets = {
        passwords = {}
      }
    }

    db = {
      secrets = {
        passwords = {}
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
