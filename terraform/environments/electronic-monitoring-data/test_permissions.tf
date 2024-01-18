resource "aws_security_group" "test_security_group" {
  name        = "test_inbound_ips"
  description = "Allowed IP addresses for testing"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "test_oakdale_ip" {
  security_group_id = aws_security_group.test_security_group.id

  cidr_ipv4   = "82.16.51.175/32"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}
resource "aws_vpc_security_group_ingress_rule" "test_fynhy_ip" {
  security_group_id = aws_security_group.test_security_group.id

  cidr_ipv4   = "46.69.144.146/32"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}
resource "aws_vpc_security_group_ingress_rule" "test_petty_france_ip" {
  security_group_id = aws_security_group.test_security_group.id

  cidr_ipv4   = "81.134.202.29/32"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}
resource "aws_vpc_security_group_ingress_rule" "test_global_protect_ip" {
  security_group_id = aws_security_group.test_security_group.id

  cidr_ipv4   = "35.176.93.186/32"
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
  server_id = aws_transfer_server.capita_transfer_server.id
  user_name = "test"
  role      = aws_iam_role.test_transfer_user_iam_role.arn

  home_directory = "/${aws_s3_bucket.capita_landing_bucket.id}/"
}

data "aws_iam_policy_document" "test_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "test_transfer_user_iam_role" {
  name                = "test-transfer-user-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.test_assume_role.json
}

data "aws_iam_policy_document" "test_transfer_user_iam_policy_document" {
  statement {
    sid       = "AllowPutAccesstoCapitaS3"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = [aws_s3_bucket.capita_landing_bucket.arn]
  }
}

resource "aws_iam_role_policy" "test_transfer_user_iam_policy" {
  name   = "test-transfer-user-iam-policy"
  role   = aws_iam_role.test_transfer_user_iam_role.id
  policy = data.aws_iam_policy_document.test_transfer_user_iam_policy_document.json
}

#------------------------------------------------------------------------------
# AWS transfer ssh key
#
# Set the public ssh key for the test user profile to access SFTP server.
#------------------------------------------------------------------------------

resource "aws_transfer_ssh_key" "test_ssh_key_mp" {
  server_id = aws_transfer_server.capita_transfer_server.id
  user_name = aws_transfer_user.test_transfer_user.user_name
  body      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCqXTKqBVVBQX5lvCdCdws4t7lCVaniv3FGCaJQOKMYAzBzwcVD9MKz0RzH7FMMA/iBayw/+13Mb79paBkJdT8T/Wg9lER/YE/lPKZcyT2IJ6myW5kDShQAY9lQliRoJ4oVx9x95hGx48eE9jWsCtwEaQT7pH2aK5l2THqfFCDQEMmT84CaSmJzuxsaYxuohlVcMqnGdU/oq+E76gLm3Z0gvh3NwFHd0RTIzqlVgwEUbTcHqZBON522229VypuvqfIcD9WIPEMnza/rA/6FX5luniqh+h/PCF7HH3Qiveui3PZV64fQtqd2pVnK8llW7CLjXKC1/TkWx1QkWyGzGYBZUXEctNbOBMixFcVbj49CucWMztPC88gZl2bHlJPqdBLMt6sakigCLWJLIvB/oeXGhzCN7XkfKWXDTu4mHuQ+UHPbXzsPvPRxidfxxRVk758M+GB15nQq2Fm3lRtYgZ2mnjQT7dwhhCaiqJiy0qs5kQ4Hs9Jnex6afoPQlqrhamtu8= matthew.price@L1057"
}

resource "aws_transfer_ssh_key" "test_ssh_key_mh" {
  server_id = aws_transfer_server.capita_transfer_server.id
  user_name = aws_transfer_user.test_transfer_user.user_name
  body      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClyRRkvW162H2NQm5IlavjE4zBhnzGJ/V+raqe7ynPumIgKhmNto8GD6iKlWkzLGxfwXQhONM/9J8+u9tqncw5FzEWEYdX/FEJF5VwLYma/OtMUio3vtwsc9zbae4EyTvROvbJSMgL07ZicUjQ9pS4+pst2KVjDtgCXD8l7A66wOkmht2Cb2Ebfk+wk965uN5wE5vHDQBx6QQ4z9UiGEp34n/g2O9gUGUJcFdYCEHVl1MY+dicCJwsRzEC1a0s/LzCtiCo66yWW8VEpMpDJNCAJccxadwWBI1d+8R94LTUakxkYhAVCpzs+A/qjaAUKsT/1KQm0+3gJIfLqmWYUumB4VgP2+cYiFbdxWQt2lLAUYZmsTwR5EktCftA5OGcwKO11sKnouj+IYiN9wfRl8kQEs+KZDDSjXKAdsWvRwhRMbBZdLqIzO2InyLCQaujZqMupMh5KkmrhL9eYFn0qtWSG274vnmUacvaIl1e8EmIb9j5ksyVXysPlIVxbNks51E= matt.heery@MJ004484"
}
