locals {
  env_label = "feasibility"

  private_subnets = [
    data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_b.id,
    data.aws_subnet.private_subnets_c.id,
  ]

  # Number of EBS apps instances; ebsapps_ami_ids needs one AMI per instance
  ebsapps_count = local.application_data.accounts[local.environment].ebsapps_count
}
