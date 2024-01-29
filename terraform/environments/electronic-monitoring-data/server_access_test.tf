#------------------------------------------------------------------------------
# AWS transfer ssh key
#
# Set the public ssh key for the test user profile to access SFTP server.
#------------------------------------------------------------------------------

resource "aws_transfer_ssh_key" "test_ssh_key_mp" {
  server_id = aws_transfer_server.capita.id
  user_name = aws_transfer_user.test_transfer_user.user_name
  body      = "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBA3BsCFaNiGxbmJffRi9q/W3aLmZWgqE6QkeFJD5O6F4nDdjsV1R0ZMUvTSoi3tKqoAE+1RYYj2Ra/F1buHov9e+sFPrlMl0wql6uMsBA1ndiIiKuq+NLY1NOxEvqm2J9Q=="
}

resource "aws_transfer_ssh_key" "test_ssh_key_mh" {
  server_id = aws_transfer_server.capita.id
  user_name = aws_transfer_user.test_transfer_user.user_name
  body      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClyRRkvW162H2NQm5IlavjE4zBhnzGJ/V+raqe7ynPumIgKhmNto8GD6iKlWkzLGxfwXQhONM/9J8+u9tqncw5FzEWEYdX/FEJF5VwLYma/OtMUio3vtwsc9zbae4EyTvROvbJSMgL07ZicUjQ9pS4+pst2KVjDtgCXD8l7A66wOkmht2Cb2Ebfk+wk965uN5wE5vHDQBx6QQ4z9UiGEp34n/g2O9gUGUJcFdYCEHVl1MY+dicCJwsRzEC1a0s/LzCtiCo66yWW8VEpMpDJNCAJccxadwWBI1d+8R94LTUakxkYhAVCpzs+A/qjaAUKsT/1KQm0+3gJIfLqmWYUumB4VgP2+cYiFbdxWQt2lLAUYZmsTwR5EktCftA5OGcwKO11sKnouj+IYiN9wfRl8kQEs+KZDDSjXKAdsWvRwhRMbBZdLqIzO2InyLCQaujZqMupMh5KkmrhL9eYFn0qtWSG274vnmUacvaIl1e8EmIb9j5ksyVXysPlIVxbNks51E= matt.heery@MJ004484"
}

#------------------------------------------------------------------------------
# AWS security group 
#
# Set the allowed IP addresses for the supplier.
#------------------------------------------------------------------------------

resource "aws_security_group" "test" {
  name        = "test_inbound_ips"
  description = "Allowed IP addresses for testing"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "test_fynhy_ip" {
  security_group_id = aws_security_group.test.id

  cidr_ipv4   = "46.69.144.146/32"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}

resource "aws_vpc_security_group_ingress_rule" "test_petty_france_ip" {
  security_group_id = aws_security_group.test.id

  cidr_ipv4   = "81.134.202.29/32"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}

#------------------------------------------------------------------------------
# AWS transfer user
#
# Create test user profile that has put access to only their landing zone
# bucket.
#------------------------------------------------------------------------------

resource "aws_transfer_user" "test_transfer_user" {
  server_id = aws_transfer_server.capita.id
  user_name = "test"
  role      = aws_iam_role.test_transfer_user_iam_role.arn

  home_directory = "/${aws_s3_bucket.capita_landing_bucket.id}/"
}

resource "aws_iam_role" "test_transfer_user_iam_role" {
  name                = "test-transfer-user-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.transfer_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

data "aws_iam_policy_document" "test_transfer_user_iam_policy_document" {
  statement {
    sid       = "AllowListAccesstoCapitaS3"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.capita_landing_bucket.arn]
  }
  statement {
    sid       = "AllowPutAccesstoCapitaS3"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.capita_landing_bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "test_transfer_user_iam_policy" {
  name   = "test-transfer-user-iam-policy"
  role   = aws_iam_role.test_transfer_user_iam_role.id
  policy = data.aws_iam_policy_document.test_transfer_user_iam_policy_document.json
}
