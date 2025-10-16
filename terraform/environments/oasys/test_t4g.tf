resource "aws_security_group" "test-sg-for-t4" {
  count = local.is-development ? 1 : 0
  #checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"
  #checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  vpc_id      = resource.aws_subnet.public_a.id
  name        = "test-sec-group"
  description = "Allow all outbound traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    label    = "app"
    Name     = "First t4 test instance"
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

  ami                         = "ami-01e9af7b9c1dfb736"
  instance_type               = "t4g.xlarge"
  vpc_security_group_ids      = [aws_security_group.test-sg-for-t4[0].id]
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  user_data_replace_on_change = true

  tags = {
    Name = "First t4 test instance"
  }
}

module "test-sg-for-t4" { #"my_t4_instance" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash; skip as this is MoJ Repo
  source    = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v3.0.1"
  subnet_id = aws_subnet.public_a.id /*ip_address.values*/
  count     = local.is-development ? 1 : 0
  providers = { aws.core-vpc = aws.core-vpc
  }
  name = "test-t4-instance"
  tags = {
    Name = "test-t4-instance"
  }
  instance = vpc-01d7a2da8f9f1dfec /* true */
  instance_profile_policies = {
  account_ids = local.environment_management.account_ids }
  environment = "test_y4g.tf"
  ami_name    = "ami-01e9af7b9c1dfb736"
  ebs_volume_config = {
    data = {
      iops       = 3000
      throughput = 125
      type       = "gp3"
  } }
  ebs_volumes = {
    "/dev/xvda" = {
      size = 30
      type = "gp3"
    }
  }
  route53_records = {
    create_internal_record = false
    create_external_record = false
  }
  /*instance_profile_policies = {
  var.instance_profile_policies
}*/
  business_unit    = module.environment.business_unit
  application_name = module.environment.application_name

}

/* instance = {
    associate_public_ip_address = false
    instance_type               = "t4g.xlarge"
    vpc_security_group_ids      = [aws_security_group.test-sg-for-t4.id]
  } */
