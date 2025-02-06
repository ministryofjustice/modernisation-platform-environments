locals {

  secretsmanager_secrets = {
    bip = {
      secrets = {
        passwords = {
          description = "BIP Passwords"
          tags = {
            instance-access-policy = "full"
          }
        }
        config = {
          description = "BIP Configuration"
          tags = {
            instance-access-policy = "limited"
          }
        }
      }
    }
    bods = {
      secrets = {
        passwords = {
          description = "BODS Passwords"
          tags = {
            instance-access-policy = "full"
          }
        }
        config = {
          description = "BODS Configuration"
          tags = {
            instance-access-policy = "limited"
          }
        }
      }
    }
    db = {
      secrets = {
        passwords = { description = "database passwords" }
      }
    }

  }
}
