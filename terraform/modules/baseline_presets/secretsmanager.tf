locals {

  secretsmanager_secrets_filter = flatten([
    var.options.enable_ec2_user_keypair ? ["/ec2/.ssh"] : [],
  ])

  secretsmanager_secrets = {
    "/ec2/.ssh" = {
      recovery_window_in_days = var.environment.environment == "development" ? 0 : 7
      secrets = {
        "ec2-user" = {
          description = "Private key for ec2-user key pair"
        }
      }
    }
  }

}
