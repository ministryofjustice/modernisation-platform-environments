
resource "aws_instance" "london_ec2" {
  ami           = "ami-0d37e07bd4ff37148" # Amazon Linux 2 (eu-west-2)
  instance_type = "t2.micro"
  vpc_id=data.aws_vpc.shared.id

  tags = {
    Name = "london-ec2"
  }
}