#------------------------------------------------------------------------------
# AWS elastic IP
#
# Assign unique IP for each supplier to connect to.
#------------------------------------------------------------------------------

resource "aws_eip" "capita_eip" {
  domain   = "vpc"
}

#------------------------------------------------------------------------------
# AWS security group 
#
# Set the allowed IP addresses for the supplier.
#------------------------------------------------------------------------------

resource "aws_security_group" "capita_security_group" {
  name        = "capita_inbound_ips"
  description = "Allowed IP addresses from Capita"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "capita_ip_1" {
  security_group_id = aws_security_group.capita_security_group.id

  cidr_ipv4   = "82.203.33.112/28"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}

resource "aws_vpc_security_group_ingress_rule" "capita_ip_2" {
  security_group_id = aws_security_group.capita_security_group.id

  cidr_ipv4   = "82.203.33.128/28"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}

resource "aws_vpc_security_group_ingress_rule" "capita_ip_3" {
  security_group_id = aws_security_group.capita_security_group.id

  cidr_ipv4   = "85.115.52.0/24"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}

resource "aws_vpc_security_group_ingress_rule" "capita_ip_4" {
  security_group_id = aws_security_group.capita_security_group.id

  cidr_ipv4   = "85.115.53.0/24"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}

resource "aws_vpc_security_group_ingress_rule" "capita_ip_5" {
  security_group_id = aws_security_group.capita_security_group.id

  cidr_ipv4   = "85.115.54.0/24"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}

#------------------------------------------------------------------------------
# AWS transfer server 
#
# Configure SFTP server for supplier that only allows supplier specified IPs.
#------------------------------------------------------------------------------


resource "aws_transfer_server" "capita_transfer_server" {
  protocols = ["SFTP"]
  identity_provider_type = "SERVICE_MANAGED"

  endpoint_type = "VPC"
  endpoint_details {
    vpc_id                 = data.aws_vpc.shared.id
    subnet_ids             = [data.aws_subnet.public_subnets_b.id]
    address_allocation_ids = [aws_eip.capita_eip.id]
    security_group_ids     = [aws_security_group.capita_security_group.id, aws_security_group.test_security_group.id]
  }

  domain = "S3"

  security_policy_name = "TransferSecurityPolicy-2023-05"

  pre_authentication_login_banner = "Hello there"
  logging_role  = aws_iam_role.test_transfer_user_iam_role.arn
  structured_log_destinations = [
    "${aws_cloudwatch_log_group.transfer.arn}:*"
  ]
}
resource "aws_cloudwatch_log_group" "transfer" {
  name_prefix = "transfer_test_"
}

#------------------------------------------------------------------------------
# AWS transfer user
#
# Create supplier user profile that has put access to only their landing zone
# bucket.
#------------------------------------------------------------------------------

resource "aws_transfer_user" "capita_transfer_user" {
  server_id = aws_transfer_server.capita_transfer_server.id
  user_name = "capita"
  role      = aws_iam_role.capita_transfer_user_iam_role.arn

  home_directory = "/${aws_s3_bucket.capita_landing_bucket.id}/"
}

data "aws_iam_policy_document" "capita_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "capita_transfer_user_iam_role" {
  name                = "capita-transfer-user-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.capita_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

data "aws_iam_policy_document" "capita_transfer_user_iam_policy_document" {
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

resource "aws_iam_role_policy" "capita_transfer_user_iam_policy" {
  name   = "capita-transfer-user-iam-policy"
  role   = aws_iam_role.capita_transfer_user_iam_role.id
  policy = data.aws_iam_policy_document.capita_transfer_user_iam_policy_document.json
}

#------------------------------------------------------------------------------
# AWS transfer ssh key
#
# Set the public ssh key for the supplier user profile to access SFTP server.
#------------------------------------------------------------------------------

resource "aws_transfer_ssh_key" "capita_ssh_key" {
  server_id = aws_transfer_server.capita_transfer_server.id
  user_name = aws_transfer_user.capita_transfer_user.user_name
  body      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCqXTKqBVVBQX5lvCdCdws4t7lCVaniv3FGCaJQOKMYAzBzwcVD9MKz0RzH7FMMA/iBayw/+13Mb79paBkJdT8T/Wg9lER/YE/lPKZcyT2IJ6myW5kDShQAY9lQliRoJ4oVx9x95hGx48eE9jWsCtwEaQT7pH2aK5l2THqfFCDQEMmT84CaSmJzuxsaYxuohlVcMqnGdU/oq+E76gLm3Z0gvh3NwFHd0RTIzqlVgwEUbTcHqZBON522229VypuvqfIcD9WIPEMnza/rA/6FX5luniqh+h/PCF7HH3Qiveui3PZV64fQtqd2pVnK8llW7CLjXKC1/TkWx1QkWyGzGYBZUXEctNbOBMixFcVbj49CucWMztPC88gZl2bHlJPqdBLMt6sakigCLWJLIvB/oeXGhzCN7XkfKWXDTu4mHuQ+UHPbXzsPvPRxidfxxRVk758M+GB15nQq2Fm3lRtYgZ2mnjQT7dwhhCaiqJiy0qs5kQ4Hs9Jnex6afoPQlqrhamtu8= test.user@K9999"
}
