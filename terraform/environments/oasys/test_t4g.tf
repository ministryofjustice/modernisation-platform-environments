resource "aws_security_group" "test-sg-for-t4" {
  count = local.is-development ? 1 : 0
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
    label    = "app"
    Name     = "First t4 test instance"
    vpc-name = "VPC created for the T4 test"
  }
}

resource "aws_instance" "my_t4_instance" {
  #checkov:skip=CKV_AWS_8: "Ensure all data stored in the Launch configuration or instance Elastic Blocks Store is securely encrypted"
  #checkov:skip=CKV_AWS_16: "Ensure all data stored in the RDS is securely encrypted at rest"
  #checkov:skip=CKV2_AWS_41: "Ensure an IAM role is attached to EC2 instance"
  #checkov:skip=CKV_AWS_79: "Ensure Instance Metadata Service Version 1 is not enabled"
  #checkov:skip=CKV_AWS_135: "Ensure that EC2 is EBS optimized"

  #count = local.is-development ? 1 : 0
  count = 0 # disabling for now as we are trying to use module

  ami                         = "ami-01e9af7b9c1dfb736"
  instance_type               = "t4g.xlarge"
  vpc_security_group_ids      = [aws_security_group.test-sg-for-t4[0].id]
  associate_public_ip_address = false
  availability_zone           = "eu-west-2a"
  ebs_optimized               = true
  user_data_replace_on_change = true
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  tags = {
    Name = "First t4 test instance"
  }
}

module "test-ec2-t4" { #"my_t4_instance" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash; skip as this is MoJ Repo
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v4.1.0"
  count  = local.is-development ? 1 : 0

  providers = {
    aws.core-vpc = aws.core-vpc
  }

  name = "test-ec2-t4"

  business_unit      = module.environment.business_unit
  application_name   = module.environment.application_name
  environment        = module.environment.environment
  region             = module.environment.region
  account_ids_lookup = module.environment.account_ids

  ami_name  = "al2023-ami-2023.8.20250915.0-kernel-6.1-arm64" # ami-01e9af7b9c1dfb736
  ami_owner = "137112412989"

  availability_zone = "eu-west-2a"
  subnet_id         = data.aws_subnet.data_subnets_a.id

  ebs_volumes_copy_all_from_ami = true
  ebs_kms_key_id                = module.environment.kms_keys["ebs"].arn
  ebs_volume_config             = {}
  ebs_volume_tags               = {}
  ebs_volumes                   = {}
  instance_profile_policies     = []

  instance = {
    disable_api_stop        = false
    disable_api_termination = true
    instance_type           = "t4g.xlarge"
    key_name                = null
    vpc_security_group_ids  = [aws_security_group.test-sg-for-t4[0].id]
  }

  route53_records = {
    create_internal_record = false
    create_external_record = false
  }

  user_data_cloud_init = {
    args = {}
    scripts = [ # paths are relative to templates/ dir
      "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent-multi-os.sh",
    ]
  }

  tags = {
    description = "test for T4G instance size"
    os-type     = "Linux"
  }
}
