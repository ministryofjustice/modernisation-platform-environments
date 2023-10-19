# Create SSM parameter to hold parameter with value to be manually added
resource "aws_ssm_parameter" "linux-join-ad-account-username" {
  name        = "/LinuxJoinDomainServiceAccountUsername"
  type        = "SecureString"
  value       = "INITIAL_VALUE_OVERRIDDEN"
  description = "Username to join linux machines to azure.noms.root domain"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "linux-join-ad-account-password" {
  name        = "/LinuxJoinDomainServiceAccountPassword"
  type        = "SecureString"
  value       = "INITIAL_VALUE_OVERRIDDEN"
  description = "Password to join linux machines to azure.noms.root domain"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}