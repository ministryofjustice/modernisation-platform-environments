locals {
  secretsmanager_secrets = {
    london_unpaid_work_admin_credentials = {
      secrets = {
        london_unpaid_work_admin_password     = { description = "london-unpaid-work admin password" }
        london_unpaid_work_username_password  = { description = "london-unpaid-work admin username" }
      }
    }
  }
}
