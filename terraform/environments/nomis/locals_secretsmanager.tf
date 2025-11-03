locals {

  secretsmanager_secrets = {
    db = {
      secrets = {
        passwords = { description = "database passwords" }
      }
    }

    db_cnom = {
      secrets = {
        passwords          = { description = "database passwords" }
        weblogic-passwords = { description = "passwords available to weblogic servers" }
      }
    }

    # this is only required because prod weblogic servers are built with "PCNOM" as DB name. Should have been "PDCNOM"
    db_pcnom = { # required because weblogic servers built with this secret name, could be re
      secrets = {
        weblogic-passwords = { description = "passwords available to weblogic servers" }
      }
    }

    db_mis = {
      secrets = {
        passwords      = { description = "database passwords" }
        misload-config = { description = "misload username, password and hostname" }
      }
    }

    web = {
      secrets = {
        passwords = { description = "weblogic passwords" }
        rms       = { description = "combined reporting secrets" }
      }
    }
  }
}
