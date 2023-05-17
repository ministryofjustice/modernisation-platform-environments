resource "aws_instance" "onprem_gateway" {
  ami           = "ami-0b5df39fc7bebda08" 
  instance_type = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.onprem_gateway.name  

  tags = {
    Name = "test"
  }
}

resource "aws_iam_instance_profile" "onprem_gateway" {
  name = "onprem_gateway"
  role = aws_iam_role.onprem_gateway.name
  path = "/"
}

resource "aws_iam_role" "onprem_gateway" {
  name               = "onprem_gateway"
  assume_role_policy = data.aws_iam_policy_document.onprem_gateway_trust_policy_doc.json
}


data "aws_iam_policy_document" "onprem_gateway_trust_policy_doc" {
  statement {
  }
}

