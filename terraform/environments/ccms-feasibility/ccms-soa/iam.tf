module "iam_ecs_ec2" {
  # main = https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/COMMIT_SHA
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/iam-role?ref=main"

  name = "${local.component_name}-${local.env_label}-ecs-ec2-role"
  trust_services = ["ec2.amazonaws.com"]
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
  create_instance_profile = true
  instance_profile_name   = "${local.component_name}-${local.env_label}-ecs-ec2-profile"
  tags                    = local.tags
}
