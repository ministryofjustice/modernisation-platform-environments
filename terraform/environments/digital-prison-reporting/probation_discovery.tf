module "probation_discovery_windows_node" {
  source = "./modules/compute_node_windows"

  enable_compute_node         = local.enable_probation_discovery_node
  name                        = "${local.project}-probation-discovery-${local.env}"
  description                 = "Probation Discovery Windows Agent"
  vpc                         = data.aws_vpc.shared.id
  cidr                        = [data.aws_vpc.shared.cidr_block]
  subnet_ids                  = data.aws_subnet.private_subnets_a.id
  ec2_instance_type           = "t3.large"
  ami_image_id                = local.probation_discovery_windows_ami_id
  aws_region                  = local.account_region
  ec2_terminate_behavior      = "terminate"
  associate_public_ip_address = false
  ebs_optimized               = true
  monitoring                  = true
  ebs_size                    = 500
  ebs_encrypted               = true
  ebs_delete_on_termination   = true
  policies = [
    "arn:aws:iam::${local.account_id}:policy/${local.s3_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.kms_read_access_policy}",
    "arn:aws:iam::${local.account_id}:policy/${local.secretsmanager_read_policy}"
  ]
  #region  = local.account_region
  #account = local.account_id
  #env     = local.env
  app_key = "probation-discovery" # points to scripts/probation-discovery.ps1

  #env_vars = {
  # ENV = local.env
  # add any app-specific env vars here
  #}

  tags = merge(
    local.all_tags,
    {
      Name               = "${local.project}-probation-discovery-${local.env}"
      dpr-name           = "${local.project}-probation-discovery-${local.env}"
      dpr-resource-type  = "EC2 Instance"
      dpr-resource-group = "probation-discovery"
      dpr-jira           = "DPR2-1980"
    }
  )

  depends_on = [aws_secretsmanager_secret.dpr_windows_rdp_credentials]
}
