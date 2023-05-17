resource "aws_instance" "onprem_gateway" {
  ami           = "ami-0b5df39fc7bebda08" 
  instance_type = "t3.medium"
#  iam_instance_profile = aws_iam_instance_profile.onprem_gateway.name  

  tags = {
    Name = "test"
  }
}

#resource "aws_iam_instance_profile" "onprem_gateway" {
#  name = "onprem_gateway"
#  role = aws_iam_role.onprem_gateway.name
#  path = "/"
#}

#resource "aws_iam_role" "onprem_gateway" {
#  name               = "onprem_gateway"
#  assume_role_policy = data.aws_iam_policy_document.onprem_gateway_trust_policy_doc.json
#}


#data "aws_iam_policy_document" "onprem_gateway_trust_policy_doc" {
#  statement {
#  }
#}


#resource "aws_security_group" "onprem_gateway" {
    
#   name        = "onprem_gateway"
#   description = "jitbit onprem gateway"
#   vpc_id      = aws_vpc.REPLACEME.id
   
#   ingress {
#    description      = ""
#    from_port        = 443
#    to_port          = 443
#    protocol         = "tcp"
#    cidr_blocks      = [aws_vpc.main.cidr_block]
#    ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
#  }

#  egress {
#    from_port        = 0
#    to_port          = 0
#    protocol         = "-1"
#    cidr_blocks      = ["0.0.0.0/0"]
#    ipv6_cidr_blocks = ["::/0"]
#  }
#
#}
