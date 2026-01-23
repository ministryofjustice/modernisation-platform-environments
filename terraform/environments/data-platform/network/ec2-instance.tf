// EC2 Instance for debugging purposes
module "debug_instance" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ec2-instance.git?ref=5e1825205b85a4fb9d10d90225e5d4d28428f49f" # v6.2.0

  name = "debug-instance"

  subnet_id     = aws_subnet.main["private-a"].id
  ami           = "ami-0942ef3175b9fe377" // Amazon Linux 2023 AMI 2023.10.20260105.0 arm64 HVM kernel-6.1
  instance_type = "t4g.micro"

  security_group_egress_rules = {
    internet-all = {
      description = "Allow EVERYTHING"
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 0
      to_port     = 65535
      ip_protocol = "tcp"
    }
  }

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}
