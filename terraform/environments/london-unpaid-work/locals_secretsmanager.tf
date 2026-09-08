locals {
  secretsmanager_secrets = {
    london_unpaid_work_admin_credentials = {
      secrets = {
        admin_password = { description = "london-unpaid-work admin password" }
        admin_username = { description = "london-unpaid-work admin username" }
      }
    }
    london_unpaid_work_application_credentials = {
      secrets = {
        encryption_key = { description = "london-unpaid-work application encryption key" }
      }
    }
    london_unpaid_work_rds_credentials = {
      secrets = {
        app_password        = { description = "london-unpaid-work rds password" }
        app_username        = { description = "london-unpaid-work rds username" }
        rds_master_password = { description = "london-unpaid-work rds master password" }
      }
    }
    london_unpaid_work_ses_credentials = {
      secrets = {
        ses_user_smtppassword = { description = "london-unpaid-work ses user smtp password" }
      }
    }
    london_unpaid_work_slack_credentials = {
      secrets = {
        token = { description = "london-unpaid-work slack token" }
      }
    }
    london_unpaid_work_test_credentials = {
      secrets = {
        test_password = { description = "london-unpaid-work test password" }
        test_username = { description = "london-unpaid-work test username" }
      }
    }
  }
}
