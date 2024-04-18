resource "aws_instance" "myec2" {
  ami           = "ami-0648ea225c13e0729"
  instance_type = "t2.micro"

  tags = {
    Name = "${local.application_name}-${terraform.workspace}-ec2"
    Environment = terraform.workspace
  }
}


resource "aws_s3_bucket" "mys3bucket" {
  bucket = "${local.application_name}-${terraform.workspace}-s3"
  acl    = "private"

  tags = {
    Name = "${local.application_name}-${terraform.workspace}-s3"
    Environment = terraform.workspace
  }
}