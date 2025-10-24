data "template_file" "launch-template" {
  template = file("${path.module}/templates/user-data.sh")
  vars = {
    cluster_name       = "${local.application_name}-cluster"
    deploy_environment = local.environment
  }
}


resource "aws_launch_template" "ec2-launch-template" {
  name_prefix   = local.application_name
  image_id      = local.application_data.accounts[local.environment].ami_image_id
  instance_type = local.application_data.accounts[local.environment].ec2_instance_type
  # key_name      = var.key_name
  ebs_optimized = true

  monitoring {
    enabled = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.cluster_ec2.id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      delete_on_termination = true
      encrypted             = false
      volume_size           = 30
      volume_type           = "gp2"
      iops                  = 0
    }
  }

  user_data = base64encode(data.template_file.launch-template.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags,
      { Name = lower(format("%s-%s-ecs-cluster", local.application_name, local.environment)) }
    )
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags,
      { instance-scheduling = "skip-scheduling" }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.tags,
      { Name = lower(format("%s-%s-ecs-cluster", local.application_name, local.environment)) }
    )
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-ecs-cluster-template", local.application_name, local.environment)) }
  )

}

resource "aws_autoscaling_group" "cluster-scaling-group" {
  name                = "${local.application_name}-auto-scaling-group"
  vpc_zone_identifier = data.aws_subnets.shared-private.ids
  desired_capacity    = local.application_data.accounts[local.environment].ec2_desired_capacity
  max_size            = local.application_data.accounts[local.environment].ec2_max_capacity
  min_size            = local.application_data.accounts[local.environment].ec2_min_capacity

  launch_template {
    id      = aws_launch_template.ec2-launch-template.id
    version = "$Latest"
  }

}