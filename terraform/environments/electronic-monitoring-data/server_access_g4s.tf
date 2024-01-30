#------------------------------------------------------------------------------
# AWS transfer user
#
# Create supplier user profile that has put access to only their landing zone
# bucket.
#------------------------------------------------------------------------------

resource "aws_transfer_user" "g4s" {
  server_id = aws_transfer_server.g4s.id
  user_name = "g4s"
  role      = aws_iam_role.g4s_transfer_user.arn

  home_directory = "/${aws_s3_bucket.g4s_landing_bucket.id}/"
}

resource "aws_iam_role" "g4s_transfer_user" {
  name                = "g4s-transfer-user-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.transfer_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

resource "aws_iam_role_policy" "g4s_transfer_user" {
  name   = "g4s-transfer-user-iam-policy"
  role   = aws_iam_role.g4s_transfer_user.id
  policy = data.aws_iam_policy_document.g4s_transfer_user.json
}

data "aws_iam_policy_document" "g4s_transfer_user" {
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

#------------------------------------------------------------------------------
# AWS transfer ssh key
#
# Set the public ssh key for the supplier user profile to access SFTP server.
#------------------------------------------------------------------------------

# resource "aws_transfer_ssh_key" "g4s_ssh_key" {
#   server_id = aws_transfer_server.g4s.id
#   user_name = aws_transfer_user.g4s.user_name
#   body      = ""
# }

#------------------------------------------------------------------------------
# AWS security group 
#
# Set the allowed IP addresses for the supplier.
#------------------------------------------------------------------------------

resource "aws_security_group" "g4s" {
  name        = "g4s_inbound_ips"
  description = "Allowed IP addresses from g4s"
  vpc_id      = data.aws_vpc.shared.id
}

# locals {
#   g4s_cidr_ipv4s = [
#   ]
# }

# resource "aws_vpc_security_group_ingress_rule" "g4s_ip" {
#   security_group_id = aws_security_group.g4s.id
  
#   description = "Allow specific access to IP address via port 2222"

#   ip_protocol = "tcp"
#   from_port   = 2222
#   to_port     = 2222

#   for_each  = { for cidr_ipv4 in local.g4s_cidr_ipv4s : cidr_ipv4 => cidr_ipv4 }
#   cidr_ipv4 = each.key
# }