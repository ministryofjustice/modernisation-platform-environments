module "sg_cluster_ec2" {
  # main = https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/COMMIT_SHA
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/security-group?ref=main"

  name        = "${local.component_name}-${local.env_label}-cluster-ec2-sg"
  description = "Controls access to the ${local.component_name} ECS cluster EC2 instances"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}
