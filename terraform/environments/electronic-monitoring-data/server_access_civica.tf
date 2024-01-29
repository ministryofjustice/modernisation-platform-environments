#------------------------------------------------------------------------------
# AWS transfer user
#
# Create supplier user profile that has put access to only their landing zone
# bucket.
#------------------------------------------------------------------------------

resource "aws_transfer_user" "civica_transfer_user" {
  server_id = aws_transfer_server.civica.id
  user_name = "civica"
  role      = aws_iam_role.civica_transfer_user_iam_role.arn

  home_directory = "/${aws_s3_bucket.civica_landing_bucket.id}/"
}

data "aws_iam_policy_document" "civica_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "civica_transfer_user_iam_role" {
  name                = "civica-transfer-user-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.civica_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

data "aws_iam_policy_document" "civica_transfer_user_iam_policy_document" {
  statement {
    sid       = "AllowListAccesstoCivicaS3"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.civica_landing_bucket.arn]
  }
  statement {
    sid       = "AllowPutAccesstoCivicaS3"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.civica_landing_bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "civica_transfer_user_iam_policy" {
  name   = "civica-transfer-user-iam-policy"
  role   = aws_iam_role.civica_transfer_user_iam_role.id
  policy = data.aws_iam_policy_document.civica_transfer_user_iam_policy_document.json
}

#------------------------------------------------------------------------------
# AWS transfer ssh key
#
# Set the public ssh key for the supplier user profile to access SFTP server.
#------------------------------------------------------------------------------

# resource "aws_transfer_ssh_key" "civica_ssh_key" {
#   server_id = aws_transfer_server.civica.id
#   user_name = aws_transfer_user.civica_transfer_user.user_name
#   body      = ""
# }

#------------------------------------------------------------------------------
# AWS security group 
#
# Set the allowed IP addresses for the supplier.
#------------------------------------------------------------------------------

resource "aws_security_group" "civica" {
  name        = "civica_inbound_ips"
  description = "Allowed IP addresses from Civica"
  vpc_id      = data.aws_vpc.shared.id
}

# resource "aws_vpc_security_group_ingress_rule" "civica_ip_1" {
#   security_group_id = aws_security_group.civica.id

#   cidr_ipv4   = ""
#   ip_protocol = "tcp"
#   from_port   = 2222
#   to_port     = 2222
# }
