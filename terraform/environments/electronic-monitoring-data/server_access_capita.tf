#------------------------------------------------------------------------------
# AWS transfer ssh key
#
# Set the public ssh key for the supplier user profile to access SFTP server.
#------------------------------------------------------------------------------

resource "aws_transfer_ssh_key" "capita_ssh_key" {
  server_id = aws_transfer_server.capita_transfer_server.id
  user_name = aws_transfer_user.capita_transfer_user.user_name
  body      = "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBIhggGYKbOk6BH7fpEs6JGRnMyLRK/9/tAMQOVYOZtehKTRcM5vGsJFRGjjm2wEan3/uYOuto0NoVkbRfIi0AIG6EWrp1gvHNQlUTtxQVp7rFeOnZAjVEE9xVUEgHhMNLw=="
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