locals {

  secretsmanager_secrets = {
    db = {
      secrets = {
        passwords = { description = "database passwords" }
      }
    }

    boe_web = {
      secrets = {
        passwords = { description = "Web Passwords" }
      }
    }

    boe_app = {
      secrets = {
        passwords = { description = "BOE Passwords" }
      }
    }

    bods = {
      secrets = {
        passwords = { description = "BODS Passwords" }
      }
    }
  }
}
