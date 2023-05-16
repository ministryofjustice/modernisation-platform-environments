resource "aws_instance" "onprem_gateway" {
  ami           = "ami-0b5df39fc7bebda08" 
  instance_type = "t3.micro"
  

  tags = {
    Name = "test"
  }
}
