#### This file can be used to store secrets specific to the member account ####
resource "aws_ssm_parameter" "gbp_exchange_rate_up_to_april_2024" {
  # checkov:skip=CKV_AWS_337: Standard KMS is fine
  name  = "/currency_rates/up_to_30-04-2024/gbp"
  type  = "SecureString"
  value = "[]" # or use a dummy like '[]'

  lifecycle {
    ignore_changes = [value] # This is critical, so its not overwritten 
  }
}

resource "aws_ssm_parameter" "gbp_exchange_rate_may_2024_to_april_2025" {
  # checkov:skip=CKV_AWS_337: Standard KMS is fine
  name  = "/currency_rates/01-05-2024_to_30-04-2025/gbp"
  type  = "SecureString"
  value = "[]" # or use a dummy like '[]'

  lifecycle {
    ignore_changes = [value] # This is critical, so its not overwritten 
  }
}

resource "aws_ssm_parameter" "gbp_exchange_rate_may_2025_to_april_2026" {
  # checkov:skip=CKV_AWS_337: Standard KMS is fine
  name  = "/currency_rates/01-05-2025_to_30-04-2026/gbp"
  type  = "SecureString"
  value = "[]" # or use a dummy like '[]'

  lifecycle {
    ignore_changes = [value] # This is critical, so its not overwritten 
  }
}