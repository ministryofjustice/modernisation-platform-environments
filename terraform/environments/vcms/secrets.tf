#### This file can be used to store secrets specific to the member account ####


resource "aws_secretsmanager_secret" "vcms-test-automation-key" {
  name                    = "vcms-test-automation-key"
  recovery_window_in_days = 0
  tags = merge(
    local.tags,
    {
      Name = "vcms-test-automation-key"
    }
  )
}
