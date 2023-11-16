
resource "aws_instance" "app_server" {
  ami           = "ami-0d729d2846a86a9e7"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}