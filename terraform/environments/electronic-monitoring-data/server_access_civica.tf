#------------------------------------------------------------------------------
# AWS transfer user
#
# Create supplier user profile that has put access to only their landing zone
# bucket.
#------------------------------------------------------------------------------

resource "aws_transfer_user" "civica" {
  server_id = aws_transfer_server.civica.id
  user_name = "civica"
  role      = aws_iam_role.civica_transfer_user.arn

  home_directory = "/${aws_s3_bucket.civica_landing_bucket.id}/"
}

resource "aws_iam_role" "civica_transfer_user" {
  name                = "civica-transfer-user-iam-role"
  assume_role_policy  = data.aws_iam_policy_document.transfer_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

resource "aws_iam_role_policy" "civica_transfer_user" {
  name   = "civica-transfer-user-iam-policy"
  role   = aws_iam_role.civica_transfer_user.id
  policy = data.aws_iam_policy_document.civica_transfer_user.json
}

data "aws_iam_policy_document" "civica_transfer_user" {
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

#------------------------------------------------------------------------------
# AWS transfer ssh key
#
# Set the public ssh key for the supplier user profile to access SFTP server.
#------------------------------------------------------------------------------

resource "aws_transfer_ssh_key" "civica_ssh_key" {
  server_id = aws_transfer_server.civica.id
  user_name = aws_transfer_user.civica.user_name
  body      = "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBCJBwZM5nMigS31soM45PITAHCmyhQpdDAkdX1liqnIZSd8A+zn3XQyVRy5E2a39gfsng5hAQetDFJKn+SaayATCQAzN0cJWlcrvtv314UsRV+PxO236sWVf+RwguUDZRQ=="
}

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

resource "aws_vpc_security_group_ingress_rule" "civica_ip_1" {
  security_group_id = aws_security_group.civica.id

  cidr_ipv4   = "20.0.26.153"
  ip_protocol = "tcp"
  from_port   = 2222
  to_port     = 2222
}
