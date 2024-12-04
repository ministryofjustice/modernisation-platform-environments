module "debug_instance" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.1"

  name                        = "network-debug"
  ami                         = "ami-0e8d228ad90af673b" # Ubuntu Server 24.04 LTS
  instance_type               = "t3.micro"
  subnet_id                   = element(module.vpc.private_subnets, 0)
  vpc_security_group_ids      = [module.debug_instance_security_group.security_group_id]
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
