# First build the security group for the EC2

resource "aws_security_group" "example-ec2-sg" {
  name        = "example-EC2-sg"
  description = "controls access to EC2"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-example", local.application_name, local.environment)) }
  )
  }
  
#  module "example-ec2" 
resource "aws_instance" "develop" {
  # Specify the instance type and ami to be used (this is the Amazon free tier option)
  instance_type          = "t2.micro"
  ami                    = "ami-0d729d2846a86a9e7"
  vpc_security_group_ids = [aws_security_group.example-ec2-sg.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id
  # Increase the volume size of the root volume
  ebs_block_device {
     volume_type          = "gp3"
     device_name          = "/dev/xvda"
     volume_size          = 20
   }
  # Add another volume to the EC2 - repeat as needed if more volumes are required.
  ebs_block_device {
     device_name          = "/dev/sdf"
     volume_type          = "gp3"
     volume_size          = 150
     throughput           = 200
     encrypted            = true
  }

  tags = {
    Name = "First terraform EC2 build"
    }
    depends_on = [aws_security_group.example-ec2-sg]
} 
# Create volumes
# resource "aws_ebs_volume" root_volume" {
#               encrypted   = true
#               volume_type = "gp3"
#               throughput  = 200
#               volume_size = 50
#               tags = {
#                 Name = "root-volume"
#               }
# }
                  
#  resource "aws_ebs_volume" "ebs_volume" {
#             {
#               device_name = "/dev/sdf"
#               volume_type = "gp3"
#               volume_size = 150
#               throughput  = 200
#               encrypted   = true
#               # kms_key_id  = aws_kms_key.this.arn
#               tags = {
#                 Name = "ebs_volume"
#               }
#             }
#  }
 
#  resource "aws_volume_attachment" "mountvolumetoec2" {
#   device_name = "/dev/sdb"
#   instance_id = "i-083aad7eac1faa3c5"
#   volume_id = "vol-0e32e4534b355c092"

# #  #Then the EC2

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
 