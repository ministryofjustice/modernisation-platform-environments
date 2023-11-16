
resource "aws_instance" "app_server" {
  ami           = "ami-0d729d2846a86a9e7"
  instance_type = "t2.micro"
  subnet_id              = data.aws_subnet.private_subnets_a.id
  security_groups = [aws_security_group.example_ec2_sg.id]
  tags = {
    Name = "ExampleAppServerInstance"
  }
}

resource "aws_security_group" "example_ec2_sg" {
  name        = "example_ec2_sg"
  description = "Controls access to EC2"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-example", local.application_name, local.environment)) }
  )
}