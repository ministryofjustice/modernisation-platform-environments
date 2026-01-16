
resource "aws_instance" "london_ec2" {
  ami           = "ami-0d37e07bd4ff37148" # Amazon Linux 2 (eu-west-2)
  instance_type = "t2.micro"
  vpc_id=data.aws_vpc.shared.id
  availability_zone           = "eu-west-2a"
  
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids      = aws_security_group.ec2_sg.id
  
  
  tags = {
    Name = "london-ec2"
  }
}



resource "aws_security_group" "ec2_sg" {
  name   = "ec2-basic-sg"
  vpc_id = data.aws_vpc.shared.id

}
