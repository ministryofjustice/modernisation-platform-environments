locals {
  secretsmanager_secrets = {
    london_unpaid_work_dev_secrets = {
      secrets = {
        admin = { description = "london-unpaid-work admin credentials" }
        app   = { description = "london-unpaid-work application credentials" }
        rds   = { description = "london-unpaid-work rds credentials" }
        ses   = { description = "london-unpaid-work ses credentials" }
        slack = { description = "london-unpaid-work slack credentials" }
        test  = { description = "london-unpaid-work test credentials" }
      }
    }
  }
}
