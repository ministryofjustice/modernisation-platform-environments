

resource "aws_security_group" "example_sg" {
  name        = "example-sg"
  description = "Security group for example instance"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sandboxtesting"
  }
}

resource "aws_instance" "example_instance" {
  ami           = "ami-00710ab5544b60cf7" 
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnets.shared_private.ids[0]
  vpc_security_group_ids = [aws_security_group.example_sg.id]

  tags = {
    Name = "sandboxtesting"
  }
}