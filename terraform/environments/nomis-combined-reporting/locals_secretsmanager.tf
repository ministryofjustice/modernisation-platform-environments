locals {

  secretsmanager_secrets = {
    bip = {
      secrets = {
        passwords = { description = "BIP Passwords" }
        config    = { description = "BIP Configuration" }
      }
    }
    bip_app = {
      secrets = {
        passwords = { description = "BIP Passwords" }
        config    = { description = "BIP Configuration" }
      }
    }
    bip_web = {
      secrets = {
        passwords = { description = "Web Passwords" }
        config    = { description = "Web Configuration" }
      }
    }
    bods = {
      secrets = {
        passwords = { description = "BODS Passwords" }
        config    = { description = "BODS Configuration" }
      }
    }
    db = {
      secrets = {
        passwords = { description = "database passwords" }
      }
    }

  }
}
