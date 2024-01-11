resource "aws_eip" "capita_eip" {
  domain   = "vpc"
}

resource "aws_security_group" "capita_security_group" {
  name        = "test_group_no_access"
  description = "Empty security group for subnet"
  vpc_id      = data.aws_vpc.shared.id

  ingress = []
  egress  = []
}

resource "aws_transfer_server" "capita_transfer_server" {
  protocols = ["SFTP"]
  identity_provider_type = "SERVICE_MANAGED"


  endpoint_type = "VPC"

  endpoint_details {
    vpc_id                 = data.aws_vpc.shared.id
    subnet_ids             = [data.aws_subnet.public_subnets_b.id]
    address_allocation_ids = [aws_eip.capita_eip.id]
    security_group_ids     = [aws_security_group.capita_security_group.id]
  }

  domain = "S3"

  pre_authentication_login_banner = "Hello there"
}