resource "aws_security_group" "vpc_endpoints" {
  description = "Security Group for controlling all VPC endpoint traffic"
  name        = format("%s-vpc-endpoint-sg", local.application_name)
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags
}

resource "aws_security_group" "transfer_server" {
  description = "Security Group for Transfer Server"
  name   = "transfer-server"
  vpc_id = module.vpc.vpc_id
}
