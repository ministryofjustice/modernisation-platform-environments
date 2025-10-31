locals {

  secretsmanager_secrets = {
    ndh = {
      secrets = {
        shared = { description = "NDH secrets for both ems and app components" }
      }
    }
  }
}
