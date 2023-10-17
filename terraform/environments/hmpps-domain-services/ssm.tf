# Create SSM parameter to hold parameter with value to be manually added
resource "aws_ssm_parameter" "linux-join-ad-account-username" {
  name        = "Linux Join Domain Service Account Username"
  type        = "SecureString"
  value       = "INITIAL_VALUE_OVERRIDDEN"
  description = "Username to join linux machines to azure.noms.root domain"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "linux-join-ad-account-password" {
  name        = "Linux Join Domain Service Account Password"
  type        = "SecureString"
  value       = "INITIAL_VALUE_OVERRIDDEN"
  description = "Password to join linux machines to azure.noms.root domain"
  tags        = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}