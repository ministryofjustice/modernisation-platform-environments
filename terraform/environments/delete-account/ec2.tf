resource "aws_instance" "myec2" {
  ami           = "ami-0648ea225c13e0729"
  instance_type = "t2.micro"
}