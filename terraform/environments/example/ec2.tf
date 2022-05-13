  #  module "example-ec2" 
resource "aws_instance" "test" {
  instance_type          = "t2.micro"
  ami                    = "ami-0d729d2846a86a9e7"

  tags = {
    Name = "First terraform EC2 build"
  }
}
  # First build the security group for the EC2

# resource "aws_security_group" "example-ec2-sg" {
#   name        = "example-EC2-sg"
#   description = "controls access to EC2"
#   #vpc_id      = data.aws_vpc.shared.id
#   vpc_id      = "vpc-0d531949a5db41ea5"
#   }

#  #Then the EC2

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
 