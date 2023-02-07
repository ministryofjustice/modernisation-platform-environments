resource "aws_instance" "Windowstest" {
  ami           = "ami-01dfbe7e4a7c6561d"
  instance_type = "t2.small"
  vpc_security_group_ids = [aws_security_group.Dev-Box-VM106.id]
  associate_public_ip_address = true
  source_dest_check           = false
  subnet_id = data.aws_subnet.public_subnets_a.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.id
  key_name      = aws_key_pair.example.key_name
    tags = {
    Name = "HelloWorld"
    backup = true
  }
}

resource "aws_instance" "Windows2" {
  ami           = "ami-01dfbe7e4a7c6561d"
  instance_type = "t2.small"
  vpc_security_group_ids = [aws_security_group.Dev-Box-VM108.id]
  associate_public_ip_address = true
  source_dest_check           = false
  subnet_id = data.aws_subnet.public_subnets_a.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.id
  key_name      = aws_key_pair.example.key_name
    tags = {
    backup = true
    Name = "HelloWorld"
}
}


resource "aws_instance" "Windows3" {
  ami           = "ami-01dfbe7e4a7c6561d"
  instance_type = "t2.small"
  vpc_security_group_ids = [aws_security_group.Dev-Box-VM108.id]
  associate_public_ip_address = true
  source_dest_check           = false
  subnet_id = data.aws_subnet.public_subnets_a.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.id
  key_name      = aws_key_pair.example.key_name

}

  resource "aws_key_pair" "example" {
  key_name   = "windowskey1"
  public_key = file("~/.ssh/windowskey.pub")
}
