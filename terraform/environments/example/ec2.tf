# First build the security group for the EC2

resource "aws_security_group" "example-ec2-sg" {
  name        = "example-EC2-sg"
  description = "controls access to EC2"
  vpc_id      = data.aws_vpc.shared.id

ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    # Need to amend this to a suitable value
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    # Need to amend this to a suitable value
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-example", local.application_name, local.environment)) }
  )
  # Need ingress and egress in here
  }
  
#  Build EC2 "example-ec2" 
resource "aws_instance" "develop" {
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type          = local.app_variables.accounts[local.environment].instance_type
  ami                    = local.app_variables.accounts[local.environment].ami_image_id
  vpc_security_group_ids = [aws_security_group.example-ec2-sg.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  # Increase the volume size of the root volume
  root_block_device {
     volume_type          = "gp3"
     volume_size          = 20
   }

  tags = merge(local.tags,
  {   Name = "First terraform EC2 build"
    }
  )
    depends_on = [aws_security_group.example-ec2-sg]
} 

# module "ec2_instance" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   # version = "~> 3.0"
#   name                   = "test-2"
#   instance_type          = "t2.micro"
#   ami                    = "ami-0d729d2846a86a9e7"
#   monitoring             = true
#   vpc_security_group_ids = [aws_security_group.example-ec2-sg.id]
#   subnet_id              = local.subnet_set

#            root_block_device = [
#             {
#               encrypted   = true
#               volume_type = "gp3"
#               throughput  = 200
#               volume_size = 50
#               tags = {
#                 Name = "root-block"
#               }
#             },
#           ]          
#           ebs_block_device = [
#             {
#               device_name = "/dev/sdf"
#               volume_type = "gp3"
#               volume_size = 50
#               throughput  = 200
#               encrypted   = true
#               # kms_key_id  = aws_kms_key.this.arn
#             }
#           ]
#  depends_on = [
# aws_security_group.example-ec2-sg
#  ]
#  }
#  resource "aws_volume_attachment" "mountvolumetoec2" {
#   # device_name = "/dev/sdb"
#   instance_id = aws_instance.develop.id
#   volume_id = aws_ebs_volume.mountvolumetoec2.id
#  }