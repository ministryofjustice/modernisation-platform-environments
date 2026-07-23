module "security_group_transfer" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  vpc_id = data.aws_vpc.shared.id

  egress_rules = {
    all-ipv4 = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound IPv4 traffic"
    }
  }

  tags = local.tags

  /*
  ingress_rules = {
    ssh-from-internet = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "SSH from Internet"
    }
    ftps-control-from-internet = {
      from_port   = 21
      to_port     = 21
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "FTPS control from Internet"
    }
    ftps-data-from-internet = {
      from_port   = 8192
      to_port     = 8200
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "FTPS data from Internet"
    }
  }
*/
}