# The security group code below is required if there is no default one in place or if you want to add a specific one.
# Uncomment the code below if this is required and chose an appropriate name  

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

# This code builds a simple EC2 instance and, if needed, increases the size of root volume (commented out at present)

resource "aws_instance" "app_server" {
  #ami           = "ami-084e8c05825742534"    # Amazon linux 64 bit
  ami = "ami-07c2ae35d31367b3e" # Canonical, Ubuntu, 22.04 LTS, amd64
  #ami           = "ami-0e322684a5a0074ce"   # Microsoft Windows Server 2022 Full Locale English
  instance_type = "t3.micro"


  # Increase the volume size of the root volume
  #   root_block_device {
  #     volume_type = "gp3"
  #     volume_size = 20
  #     encrypted   = true
  #   }

  tags = {
    Name = "example-EC2"
  }
}

# This is needed to add a role which can be used to allow access to the instance created.

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
}
