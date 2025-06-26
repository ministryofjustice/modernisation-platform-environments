module "datasync_instance" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.0.1"

  name = "${local.application_name}-${local.environment}-datasync"
  # ami                    = data.aws_ssm_parameter.datasync_ami.value
  ami                    = "ami-037ee8c0ba1cbd1f6" # TODO: Remove hardcoded AMI
  instance_type          = "m5.2xlarge"
  subnet_id              = element(module.connected_vpc.private_subnets, 0)
  vpc_security_group_ids = [module.datasync_instance_security_group.security_group_id]
  private_ip             = local.environment_configuration.datasync_instance_private_ip

  metadata_options = {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }

  enable_volume_tags = false
  root_block_device = [
    {
      encrypted   = true
      kms_key_id  = module.ec2_ebs_kms.key_arn
      volume_type = "gp2"
      volume_size = 200
      tags = merge(
        local.tags,
        { Name = "${local.application_name}-${local.environment}-datasync-root" }
      )
    }
  ]

  tags = merge(
    local.tags,
    {
      Name                = "${local.application_name}-${local.environment}-datasync"
      instance-scheduling = "skip-scheduling" # TEMPORARY
    }
  )
}

/* This instance is temporary and will be retired when we're satisfied with DataSync end-to-end */
module "mojo_network_debug_instance" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.0.1"

  name                        = "mojo-network-debug"
  ami                         = "ami-0acc77abdfc7ed5a6"
  instance_type               = "t3.micro"
  subnet_id                   = element(module.connected_vpc.private_subnets, 0)
  vpc_security_group_ids      = [module.mojo_network_debug_security_group.security_group_id]
  associate_public_ip_address = false

  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      volume_size = 8
    }
  ]

  create_iam_instance_profile = true
  iam_role_policies = {
    SSMCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  metadata_options = {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }

  tags = local.tags
}
