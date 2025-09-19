resource "aws_instance" "my_t4_instance" {
  #checkov:skip=CKV_AWS_79: "Ensure Instance Metadata Service Version 1 is not enabled"
  #checkov:skip=CKV_AWS_135: "Ensure that EC2 is EBS optimized"
  #checkov:skip=CKV_AWS_16: "Ensure all data stored in the RDS is securely encrypted at rest"
  #checkov:skip=CKV2_AWS_41: "Ensure an IAM role is attached to EC2 instance"
  #checkov:skip=CKV_AWS_8: "Ensure all data stored in the Launch configuration or instance Elastic Blocks Store is securely encrypted"

  count         = local.is-development ? 1 : 0
  ami           = "ami-08f714c552929eda9"
  instance_type = "t4g.micro"

  vpc_security_group_ids = ["subnet-072949a209fe05fb3"]

  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  user_data_replace_on_change = true
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  tags = {
    Name = "First t4 instance"
  }

}

