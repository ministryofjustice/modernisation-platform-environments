locals {

  secretsmanager_secrets = {
    db = {
      secrets = {
        passwords = { description = "database passwords" }
      }
    }

    bip = {
      secrets = {
        passwords = { description = "BIP Passwords" }
        config    = { description = "BIP Configuration" }
      }
    }

    bods = {
      secrets = {
        passwords = { description = "BODS Passwords" }
        config    = { description = "BODS Configuration" }
      }
    }

    github_pat = {
      secrets = {
        pat = { description = "github-hmpps-dso-automation-pat" }
      }
    }
  }
}
