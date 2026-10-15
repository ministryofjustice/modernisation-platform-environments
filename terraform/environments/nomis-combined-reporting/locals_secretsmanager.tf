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
    sharepoint = {
      secrets = {
        app-registration = {
          description = "App registration credentials for SharePoint access"
        }
        drive-ids = {
          description = "SharePoint Drive Ids"
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
