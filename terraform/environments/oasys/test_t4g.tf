resource "aws_security_group" "test-sg-for-t4" {

  #checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  vpc_id      = data.aws_vpc.shared.id
  name        = "test-sec-group"
  description = "Allow all outbound traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {

    vpc-name = "VPC created for the T4 test"
  }
}
locals {
  cloudwatch_metric_alarms_endpoint_monitoring = {
    Decription = "Set the endpoint location"
    type       = "string"
  }
}
resource "aws_instance" "my_t4_instance" {
  #checkov:skip=CKV_AWS_8: "Ensure all data stored in the Launch configuration or instance Elastic Blocks Store is securely encrypted"
  #checkov:skip=CKV_AWS_16: "Ensure all data stored in the RDS is securely encrypted at rest"
  #checkov:skip=CKV2_AWS_41: "Ensure an IAM role is attached to EC2 instance"
  #checkov:skip=CKV_AWS_79: "Ensure Instance Metadata Service Version 1 is not enabled"
  #checkov:skip=CKV_AWS_135: "Ensure that EC2 is EBS optimized"



  count = local.is-development ? 1 : 0
  ami   = "ami-03823b6730d398a3f"

  instance_type = "t4g.micro"

  vpc_security_group_ids = [aws_security_group.test-sg-for-t4.id]

  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  user_data_replace_on_change = true
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  tags = {
    Name = "First t4 test instance"
  }
}
