locals {

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
