locals {

  secretsmanager_secrets = {
    bip_app = {
      secrets = {
        passwords = { description = "BIP Passwords" }
      }
    }
    bip_web = {
      secrets = {
        passwords = { description = "Web Passwords" }
      }
    }
    bods = {
      secrets = {
        passwords = { description = "ETL Passwords" }
      }
    }
    db = {
      secrets = {
        passwords = { description = "database passwords" }
      }
    }

  }
}
