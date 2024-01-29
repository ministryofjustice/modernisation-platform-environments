#------------------------------------------------------------------------------
# AWS transfer user
#
# Create test user profile that has put access to only their landing zone
# bucket.
#------------------------------------------------------------------------------

resource "aws_transfer_user" "test_capita" {
  server_id = aws_transfer_server.capita.id
  user_name = "test"
  role      = aws_iam_role.capita_transfer_user.arn

  home_directory = "/${aws_s3_bucket.capita_landing_bucket.id}/"
}

resource "aws_transfer_user" "test_civica" {
  server_id = aws_transfer_server.civica.id
  user_name = "test"
  role      = aws_iam_role.civica_transfer_user.arn

  home_directory = "/${aws_s3_bucket.civica_landing_bucket.id}/"
}

resource "aws_transfer_user" "test_g4s" {
  server_id = aws_transfer_server.g4s.id
  user_name = "test"
  role      = aws_iam_role.g4s_transfer_user.arn

  home_directory = "/${aws_s3_bucket.g4s_landing_bucket.id}/"
}

#------------------------------------------------------------------------------
# AWS transfer ssh key
#
# Set the public ssh key for the test user profiles to access SFTP server.
#------------------------------------------------------------------------------

locals {
  ssh_keys = [
    # Matt Price
    "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBA3BsCFaNiGxbmJffRi9q/W3aLmZWgqE6QkeFJD5O6F4nDdjsV1R0ZMUvTSoi3tKqoAE+1RYYj2Ra/F1buHov9e+sFPrlMl0wql6uMsBA1ndiIiKuq+NLY1NOxEvqm2J9Q==",
    # Matt Heery
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClyRRkvW162H2NQm5IlavjE4zBhnzGJ/V+raqe7ynPumIgKhmNto8GD6iKlWkzLGxfwXQhONM/9J8+u9tqncw5FzEWEYdX/FEJF5VwLYma/OtMUio3vtwsc9zbae4EyTvROvbJSMgL07ZicUjQ9pS4+pst2KVjDtgCXD8l7A66wOkmht2Cb2Ebfk+wk965uN5wE5vHDQBx6QQ4z9UiGEp34n/g2O9gUGUJcFdYCEHVl1MY+dicCJwsRzEC1a0s/LzCtiCo66yWW8VEpMpDJNCAJccxadwWBI1d+8R94LTUakxkYhAVCpzs+A/qjaAUKsT/1KQm0+3gJIfLqmWYUumB4VgP2+cYiFbdxWQt2lLAUYZmsTwR5EktCftA5OGcwKO11sKnouj+IYiN9wfRl8kQEs+KZDDSjXKAdsWvRwhRMbBZdLqIzO2InyLCQaujZqMupMh5KkmrhL9eYFn0qtWSG274vnmUacvaIl1e8EmIb9j5ksyVXysPlIVxbNks51E= matt.heery@MJ004484"
  ]
}

resource "aws_transfer_ssh_key" "test_capita_ssh_key" {
  server_id = aws_transfer_server.capita.id
  user_name = aws_transfer_user.test_capita.user_name

  for_each  = { for ssh_key in local.ssh_keys : ssh_key => ssh_key }
  body      = each.key
}

resource "aws_transfer_ssh_key" "test_civica_ssh_key" {
  server_id = aws_transfer_server.civica.id
  user_name = aws_transfer_user.test_civica.user_name

  for_each  = { for ssh_key in local.ssh_keys : ssh_key => ssh_key }
  body      = each.key
}

resource "aws_transfer_ssh_key" "test_g4s_ssh_key" {
  server_id = aws_transfer_server.g4s.id
  user_name = aws_transfer_user.test_g4s.user_name

  for_each  = { for ssh_key in local.ssh_keys : ssh_key => ssh_key }
  body      = each.key
}

#------------------------------------------------------------------------------
# AWS security group 
#
# Set the allowed IP addresses for the supplier.
#------------------------------------------------------------------------------
locals {
  cidr_ipv4s = [
    # fy nhy
    "46.69.144.146/32",
    # Petty France
    "81.134.202.29/32"
  ]
}

resource "aws_security_group" "test" {
  name        = "test_inbound_ips"
  description = "Allowed IP addresses for testing"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "test_fynhy_ip" {
  security_group_id = aws_security_group.test.id

  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222

  for_each  = { for cidr_ipv4 in local.cidr_ipv4s : cidr_ipv4 => cidr_ipv4 }
  cidr_ipv4 = each.key
}
