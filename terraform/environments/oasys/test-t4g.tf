resource "aws_instance" "my_instance" {
  #checkov:skip=CKV_AWS_79: "Ensure Instance Metadata Service Version 1 is not enabled"
  #checkov:skip=CKV_AWS_135: "Ensure that EC2 is EBS optimized"
  #checkov:skip=CKV_AWS_16: "Ensure all data stored in the RDS is securely encrypted at rest"
  #checkov:skip=CKV2_AWS_41: "Ensure an IAM role is attached to EC2 instance"
  #checkov:skip=CKV_AWS_8: "Ensure all data stored in the Launch configuration or instance Elastic Blocks Store is securely encrypted"

  count         = local.is-development ? 1 : 0
  ami           = "ami-08f714c552929eda9"
  instance_type = "t4g.micro"
  # Code from elsewhere
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  monitoring                  = true
  user_data_replace_on_change = true
  tags = {
    Name = "First t4 instance"
  }

}
