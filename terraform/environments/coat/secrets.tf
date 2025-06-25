#### This file can be used to store secrets specific to the member account ####
resource "aws_ssm_parameter" "gbp_exchange_rate_up_to_april" {
  # checkov:skip=CKV_AWS_337: Standard KMS is fine
  name  = "/currency_rates/up_to_april/gbp"
  type  = "SecureString"
  value = "[]" # or use a dummy like '[]'

  lifecycle {
    ignore_changes = [value] # This is critical, so its not overwritten 
  }
}

resource "aws_ssm_parameter" "gbp_exchange_rate_april_to_may" {
  # checkov:skip=CKV_AWS_337: Standard KMS is fine
  name  = "/currency_rates/april_to_may/gbp"
  type  = "SecureString"
  value = "[]" # or use a dummy like '[]'

  lifecycle {
    ignore_changes = [value] # This is critical, so its not overwritten 
  }
}

resource "aws_ssm_parameter" "gbp_exchange_rate_may" {
  # checkov:skip=CKV_AWS_337: Standard KMS is fine
  name  = "/currency_rates/may/gbp"
  type  = "SecureString"
  value = "[]" # or use a dummy like '[]'

  lifecycle {
    ignore_changes = [value] # This is critical, so its not overwritten 
  }
}