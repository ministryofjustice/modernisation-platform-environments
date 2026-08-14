data "template_file" "launch-template-main" {
  template = file("${path.module}/templates/user-data-main.sh")
  vars = {
    cluster_name       = "${local.first_cluster_name}"
    deploy_environment = local.environment
  }
}
# efs_id             = aws_efs_file_system.oia-storage.id

data "template_file" "launch-template-additional" {
  template = file("${path.module}/templates/user-data-additional.sh")
  vars = {
    cluster_name       = "${local.second_cluster_name}"
    deploy_environment = local.environment
  }
}

    # efs_id             = aws_efs_file_system.oia-storage.id
resource "aws_launch_template" "ec2_launch_template_main" {
  name_prefix   = local.first_cluster_name
  image_id      = local.application_data.accounts[local.environment].ami_image_id
  instance_type = local.application_data.accounts[local.environment].ec2_instance_type
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
      encrypted             = true
      volume_size           = 30
      volume_type           = "gp2"
    }
  }

  user_data = base64encode(data.template_file.launch-template-main.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags,
      { Name = lower(format("%s-%s-ecs-cluster", local.first_cluster_name, local.environment)) }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.tags,
      { Name = lower(format("%s-%s-ecs-cluster", local.first_cluster_name, local.environment)) }
    )
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-ecs-cluster-template", local.first_cluster_name, local.environment)) }
  )
}

resource "aws_autoscaling_group" "main_cluster_scaling_group" {
  name                  = "${local.first_cluster_name}-auto-scaling-group"
  vpc_zone_identifier   = data.aws_subnets.shared-private.ids
  desired_capacity      = local.application_data.accounts[local.environment].main_cluster_ec2_desired_capacity
  max_size              = local.application_data.accounts[local.environment].main_cluster_ec2_max_size
  min_size              = local.application_data.accounts[local.environment].main_cluster_ec2_min_size
  protect_from_scale_in = true

  launch_template {
    id      = aws_launch_template.ec2_launch_template_main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.first_cluster_name}-ecs-instance"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "ec2_launch_template_additional" {
  name_prefix   = local.second_cluster_name
  image_id      = local.application_data.accounts[local.environment].ami_image_id
  instance_type = local.application_data.accounts[local.environment].ec2_instance_type
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
      encrypted             = true
      volume_size           = 30
      volume_type           = "gp2"
    }
  }

  user_data = base64encode(data.template_file.launch-template-additional.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags,
      { Name = lower(format("%s-%s-ecs-cluster", local.second_cluster_name, local.environment)) }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.tags,
      { Name = lower(format("%s-%s-ecs-cluster", local.second_cluster_name, local.environment)) }
    )
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-ecs-cluster-template", local.second_cluster_name, local.environment)) }
  )
}

resource "aws_autoscaling_group" "additional_cluster_scaling_group" {
  name                  = "${local.second_cluster_name}-auto-scaling-group"
  vpc_zone_identifier   = data.aws_subnets.shared-private.ids
  desired_capacity      = local.application_data.accounts[local.environment].additional_cluster_ec2_desired_capacity
  max_size              = local.application_data.accounts[local.environment].additional_cluster_ec2_max_size
  min_size              = local.application_data.accounts[local.environment].additional_cluster_ec2_min_size
  protect_from_scale_in = true

  launch_template {
    id      = aws_launch_template.ec2_launch_template_additional.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.second_cluster_name}-ecs-instance"
    propagate_at_launch = true
  }
}
