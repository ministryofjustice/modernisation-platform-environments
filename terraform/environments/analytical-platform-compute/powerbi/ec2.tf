################################################################################
# PowerBI Gateway - EC2 Instances
################################################################################

# Create the PowerBI Gateway EC2 Instance
module "powerbi_gateway_ec2" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-development" ? 1 : 0

  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.0.1"

  name                        = local.powerbi_gateway_instance_name
  ami                         = data.aws_ami.windows_server_2025.id
  instance_type               = local.environment_configuration.powerbi_gateway.instance_type
  key_name                    = aws_key_pair.powerbi_gateway_keypair.key_name
  monitoring                  = local.environment_configuration.powerbi_gateway.enable_monitoring
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for PowerBI Gateway Instance"
  ignore_ami_changes          = true
  enable_volume_tags          = false
  associate_public_ip_address = false
  iam_role_name               = local.powerbi_gateway_role

  iam_role_policies = {
    SSMCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }

  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      volume_size = local.environment_configuration.powerbi_gateway.root_volume_size
      tags = merge({
        Name = "${local.powerbi_gateway_instance_name}-root-volume"
      }, local.tags, local.environment_configuration.powerbi_gateway.tags)
    }
  ]

  ebs_block_device = [
    {
      volume_type = "gp3"
      device_name = "/dev/sdf"
      volume_size = local.environment_configuration.powerbi_gateway.data_volume_size
      encrypted   = true
      tags = merge({
        Name = "${local.powerbi_gateway_instance_name}-data-volume"
      }, local.tags, local.environment_configuration.powerbi_gateway.tags)
    }
  ]

  metadata_options = {
    http_tokens = "required"
  }

  vpc_security_group_ids = [module.powerbi_gateway_security_group.security_group_id]
  subnet_id              = data.aws_subnet.private_subnets_a.id

  tags = merge(local.tags, local.environment_configuration.powerbi_gateway.tags, {
    Component = "powerbi-gateway"
  })
}
