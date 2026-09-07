locals {
  secretsmanager_secrets = {
    london_unpaid_work_admin_credentials = {
      secrets = {
        london_unpaid_work_admin_password     = { description = "london-unpaid-work admin password" }
        london_unpaid_work_admin_username     = { description = "london-unpaid-work admin username" }
      }
    }
    london_unpaid_work_test_credentials = {
      secrets = {
        london_unpaid_work_test_password     = { description = "london-unpaid-work test password" }
        london_unpaid_work_test_username     = { description = "london-unpaid-work test username" }
      }
    }
  }
}
