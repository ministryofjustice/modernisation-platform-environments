locals {
  env_label = "upg"

  # component_name is "ccms-ebs-ref"; split out so instance-level DNS names can
  # follow the same base-a{n}-suffix shape as ccms-feasibility/ccms-ebs while
  # keeping "ref-upg" together as the trailing block that identifies this stack
  ebs_base    = "ccms-ebs"
  ebs_variant = "ref"

  private_subnets = [
    data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_b.id,
    data.aws_subnet.private_subnets_c.id,
  ]
}
