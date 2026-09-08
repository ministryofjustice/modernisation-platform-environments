module "gh_runner" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/b484555
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/ec2?ref=b484555"

  name                  = "${local.component_name}-${local.env_label}-gh-runner"
  instance_profile_name = aws_iam_instance_profile.github_runner_instance_profile.name

  instance_type      = local.application_data.accounts[local.environment].ec2_instance_type_gh_runner
  ami_id             = local.application_data.accounts[local.environment].gh_runner_ami_id
  subnet_id          = data.aws_subnet.private_subnets_a.id
  security_group_ids = [aws_security_group.ec2_sg_gh_runner.id]
  monitoring         = true
  ebs_optimized      = true

  user_data = base64encode(templatefile("./templates/user_data_gh_runner.sh", {
    hostname = "github-runner"
  }))

  tags = merge(local.tags, {
    instance-role       = local.application_data.accounts[local.environment].instance_role_gh_runner
    instance-scheduling = "skip-scheduling"
    backup              = "true"
  })
}
