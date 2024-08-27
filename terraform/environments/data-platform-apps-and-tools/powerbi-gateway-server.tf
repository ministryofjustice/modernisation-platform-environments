data "aws_ami" "windows_server_2022" {
  most_recent = local.environment_configuration.powerbi_gateway_ec2.most_recent
  owners      = [local.environment_configuration.powerbi_gateway_ec2.owner_account]

  filter {
    name   = "name"
    values = local.environment_configuration.powerbi_gateway_ec2.name
  }
  filter {
    name   = "virtualization-type"
    values = [local.environment_configuration.powerbi_gateway_ec2.virtualization_type]
  }
}
module "powerbi_gateway" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.0"

  name = local.environment_configuration.powerbi_gateway_ec2.instance_name
  # ami                         = data.aws_ami.windows_server_2022.id
  ami                         = "ami-00ffeb610527f540b" # Hardcoded AMI ID for Windows Server 2022
  instance_type               = local.environment_configuration.powerbi_gateway_ec2.instance_type
  key_name                    = aws_key_pair.powerbi_gateway_keypair.key_name
  monitoring                  = true
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for PowerBI Gateway Instance"
  ignore_ami_changes          = false
  enable_volume_tags          = false
  associate_public_ip_address = false
  iam_role_policies = {
    SSMCore            = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    PowerBI_DataAccess = aws_iam_policy.powerbi_gateway_data_access.arn
  }
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      volume_size = 100
      tags = merge({
        Name = "${local.environment_configuration.powerbi_gateway_ec2.instance_name}-root-volume"
      }, local.tags)
    },
  ]

  ebs_block_device = [
    {
      volume_type = "gp3"
      device_name = "/dev/sdf"
      volume_size = 300
      encrypted   = true
      tags = merge({
        Name = "${local.environment_configuration.powerbi_gateway_ec2.instance_name}-data-volume"
      }, local.tags)
    }
  ]
  vpc_security_group_ids = [aws_security_group.powerbi_gateway.id]
  subnet_id              = data.aws_subnet.private_subnets_a.id

  tags = local.tags
}
