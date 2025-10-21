resource "aws_instance" "ec2_gh_runner" {
  instance_type               = local.application_data.accounts[local.environment].ec2_instance_type_gh_runner
  ami                         = local.application_data.accounts[local.environment].gh_runner_ami_id
  iam_instance_profile        = aws_iam_instance_profile.github_runner_instance_profile.name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_gh_runner.id]
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  monitoring                  = true
  ebs_optimized               = true
  associate_public_ip_address = false

  user_data_replace_on_change = false
  user_data = base64encode(templatefile("./templates/user_data_gh_runner.sh", {
    hostname = "github-runner"
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    iops        = 3000
    tags = merge(local.tags,
      { Name = lower(format("%s-%s", local.application_data.accounts[local.environment].instance_role_gh_runner, "root")) },
      { device-name = "/dev/sda1" }
    )
  }

  tags = merge(local.tags,
    { Name = lower(format("github-runner-%s", local.environment)) },
    { instance-role = local.application_data.accounts[local.environment].instance_role_gh_runner },
    { instance-scheduling = "skip-scheduling" },
    { backup = "true" }
  )

  depends_on = [aws_security_group.ec2_sg_gh_runner]
}
