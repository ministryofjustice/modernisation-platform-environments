locals {

  secretsmanager_secrets = {
    db = {
      secrets = {
        passwords = { description = "database passwords" }
      }
    }

    web = {
      secrets = {
        passwords = { description = "Web Passwords" }
      }
    }

    bip = {
      secrets = {
        passwords = { description = "BIP Passwords" }
      }
    }

    bods = {
      secrets = {
        passwords = { description = "BODS Passwords" }
      }
    }
  }
}
