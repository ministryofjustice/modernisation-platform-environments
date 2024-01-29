#------------------------------------------------------------------------------
# AWS transfer user
#
# Create supplier user profile that has put access to only their landing zone
# bucket.
#------------------------------------------------------------------------------

resource "aws_transfer_user" "g4s_transfer_user" {
  server_id = aws_transfer_server.g4s.id
  user_name = "g4s"
  role      = aws_iam_role.g4s_transfer_user_iam_role.arn

  home_directory = "/${aws_s3_bucket.g4s_landing_bucket.id}/"
}

data "aws_iam_policy_document" "g4s_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "g4s_transfer_user_iam_role" {
  name                = "g4s-transfer-user-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.g4s_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

data "aws_iam_policy_document" "g4s_transfer_user_iam_policy_document" {
  statement {
    sid       = "AllowListAccesstoG4sS3"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.g4s_landing_bucket.arn]
  }
  statement {
    sid       = "AllowPutAccesstoG4sS3"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.g4s_landing_bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "g4s_transfer_user_iam_policy" {
  name   = "g4s-transfer-user-iam-policy"
  role   = aws_iam_role.g4s_transfer_user_iam_role.id
  policy = data.aws_iam_policy_document.g4s_transfer_user_iam_policy_document.json
}

#------------------------------------------------------------------------------
# AWS transfer ssh key
#
# Set the public ssh key for the supplier user profile to access SFTP server.
#------------------------------------------------------------------------------

# resource "aws_transfer_ssh_key" "g4s_ssh_key" {
#   server_id = aws_transfer_server.g4s.id
#   user_name = aws_transfer_user.g4s_transfer_user.user_name
#   body      = ""
# }

#------------------------------------------------------------------------------
# AWS security group 
#
# Set the allowed IP addresses for the supplier.
#------------------------------------------------------------------------------

resource "aws_security_group" "g4s_security_group" {
  name        = "g4s_inbound_ips"
  description = "Allowed IP addresses from g4s"
  vpc_id      = data.aws_vpc.shared.id
}

# resource "aws_vpc_security_group_ingress_rule" "g4s_ip_1" {
#   security_group_id = aws_security_group.g4s_security_group.id

#   cidr_ipv4   = ""
#   ip_protocol = "tcp"
#   from_port   = 2222
#   to_port     = 2222
# }
