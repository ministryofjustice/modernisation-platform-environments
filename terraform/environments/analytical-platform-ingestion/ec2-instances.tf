module "datasync_instance" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.0"

  name                   = "${local.application_name}-${local.environment}-datasync"
  ami                    = data.aws_ami.datasync.id
  instance_type          = "m5.2xlarge"
  subnet_id              = element(module.connected_vpc.private_subnets, 0)
  vpc_security_group_ids = [module.datasync_security_group.security_group_id]

  root_block_device = {
    encrypted   = true
    kms_key_id  = module.ec2_ebs_kms.key_arn
    volume_type = "gp3"
    volume_size = 80

  }
}
