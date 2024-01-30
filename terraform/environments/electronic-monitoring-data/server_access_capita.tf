#------------------------------------------------------------------------------
# AWS transfer user
#
# Create supplier user profile that has put access to only their landing zone
# bucket.
#------------------------------------------------------------------------------

resource "aws_transfer_user" "capita_transfer_user" {
  server_id = aws_transfer_server.capita.id
  user_name = "capita"
  role      = aws_iam_role.capita_transfer_user_iam_role.arn

  home_directory = "/${aws_s3_bucket.capita_landing_bucket.id}/"
}

resource "aws_iam_role" "capita_transfer_user_iam_role" {
  name                = "capita-transfer-user-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.transfer_assume_role.json
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
  server_id = aws_transfer_server.capita.id
  user_name = aws_transfer_user.capita_transfer_user.user_name
  body      = "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBIhggGYKbOk6BH7fpEs6JGRnMyLRK/9/tAMQOVYOZtehKTRcM5vGsJFRGjjm2wEan3/uYOuto0NoVkbRfIi0AIG6EWrp1gvHNQlUTtxQVp7rFeOnZAjVEE9xVUEgHhMNLw=="
}

#------------------------------------------------------------------------------
# AWS security group 
#
# Set the allowed IP addresses for the supplier.
#------------------------------------------------------------------------------

resource "aws_security_group" "capita" {
  name        = "capita_inbound_ips"
  description = "Allowed IP addresses from Capita"
  vpc_id      = data.aws_vpc.shared.id
}

resource "aws_vpc_security_group_ingress_rule" "capita_ip_1" {
  security_group_id = aws_security_group.capita.id

  cidr_ipv4   = "82.203.33.112/28"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}

resource "aws_vpc_security_group_ingress_rule" "capita_ip_2" {
  security_group_id = aws_security_group.capita.id

  cidr_ipv4   = "82.203.33.128/28"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}

resource "aws_vpc_security_group_ingress_rule" "capita_ip_3" {
  security_group_id = aws_security_group.capita.id

  cidr_ipv4   = "85.115.52.0/24"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}

resource "aws_vpc_security_group_ingress_rule" "capita_ip_4" {
  security_group_id = aws_security_group.capita.id

  cidr_ipv4   = "85.115.53.0/24"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}

resource "aws_vpc_security_group_ingress_rule" "capita_ip_5" {
  security_group_id = aws_security_group.capita.id

  cidr_ipv4   = "85.115.54.0/24"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}