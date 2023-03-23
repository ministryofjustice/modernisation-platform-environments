module "baseline" {
  source = "../../modules/baseline"

  providers = {
    aws                       = aws
    aws.core-network-services = aws.core-network-services
    aws.core-vpc              = aws.core-vpc
  }

  bastion_linux = lookup(local.environment_config, "baseline_bastion_linux", null)
  environment   = module.environment
  # ec2_autoscaling_groups = lookup(local.environment_config, "baseline_ec2_autoscaling_groups", {})
}
