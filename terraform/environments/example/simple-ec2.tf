# This code below shows the bulding of a security group if there is no default one in place. Uncomment this code if it is required otherwise leave as is and used the resource code below

# resource "aws_security_group" "example_ec2_sg" {
#   name        = "example_ec2_sg"
#   description = "Controls access to EC2"
#   vpc_id      = data.aws_vpc.shared.id
#   tags = merge(local.tags,
#     { Name = lower(format("sg-%s-%s-example", local.application_name, local.environment)) }
#   )
# }
# resource "aws_security_group_rule" "ingress_traffic" {
#   for_each          = local.application_data.example_ec2_sg_rules
#   description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
#   from_port         = each.value.from_port
#   protocol          = each.value.protocol
#   security_group_id = aws_security_group.example_ec2_sg.id
#   to_port           = each.value.to_port
#   type              = "ingress"
#   cidr_blocks       = [data.aws_vpc.shared.cidr_block]
# }

# resource "aws_security_group_rule" "egress_traffic" {
#   for_each                 = local.application_data.example_ec2_sg_rules
#   description              = format("Outbound traffic for %s %d", each.value.protocol, each.value.from_port)
#   from_port                = each.value.from_port
#   protocol                 = each.value.protocol
#   security_group_id        = aws_security_group.example_ec2_sg.id
#   to_port                  = each.value.to_port
#   type                     = "egress"
#   source_security_group_id = aws_security_group.example_ec2_sg.id
# }

# This section sets up a basic quick EC2 server without any options. If you need you can add additional volumes, change the size from micro to large (for example) 
# 3 instance types are listed - uncomment the one you need and comment out the others. If you want a different name replace "example-EC2" with your preferred name.

resource "aws_instance" "app_server" {
  ami           = "ami-084e8c05825742534"    # Amazon linux 64 bit
  #ami           = "ami-07c2ae35d31367b3e"   # Canonical, Ubuntu, 22.04 LTS, amd64
  #ami           = "ami-0e322684a5a0074ce"   # Microsoft Windows Server 2022 Full Locale English
  instance_type = "t3.micro"

 # If the root volume size is too small you can increase the volume size of the root volume by uncommenting the code below
  
  # root_block_device {
  #   volume_type = "gp3"
  #   volume_size = 20
  #   encrypted   = true
  # }

  tags = {
    Name = "example-EC2" 
  }
}

# A role is required to allow access to the new EC2 instance. If you want a different name replace "example-EC2" with your preferred name.

resource "aws_iam_role" "this" {
  name                 = "example-EC2-role"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
