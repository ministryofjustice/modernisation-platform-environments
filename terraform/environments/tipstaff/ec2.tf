resource "aws_instance" "tipstaff-ec2-instance-dev" {

  instance_type = local.application_data.accounts[local.environment].instance_type
  ami = local.application_data.accounts[local.environment].ami
  count = "1"
  subnet_id = data.aws_subnets.data_subnets_a.id
  vpc_security_group_ids = [aws_security_group.tipstaff-dev-ec2-sc.id]

}

resource "aws_security_group" "tipstaff-dev-ec2-sc" {
  name        = "ec2 security group"
  description = "control access to the ec2 instance"
  vpc_id      = data.aws_vpc.shared.id
  ingress {
    description = "Allow all traffic through HTTP"
    from_port = "80"
    to_port   = "80"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//May also need a load balancer