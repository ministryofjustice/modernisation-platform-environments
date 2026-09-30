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
  name                    = "${local.application_name}-auto-scaling-group"
  vpc_zone_identifier     = data.aws_subnets.shared-private.ids
  # Desired count = 2 for production, 1 for non-production envs
  desired_capacity        = local.ecs_asg_desired_capacity
  max_size                = local.ecs_asg_max_size
  min_size                = local.ecs_asg_min_size
  protect_from_scale_in   = true
  default_instance_warmup = 0
  # validate min_size <= desired_capacity <= max_size
  lifecycle {
    precondition {
      condition     = local.ecs_asg_desired_capacity >= local.ecs_asg_min_size && local.ecs_asg_desired_capacity <= local.ecs_asg_max_size
      error_message = "Desired capacity must be greater than or equal to the minimum size and less than or equal to the maximum size."
    }
  }

  launch_template {
    id      = aws_launch_template.ec2-launch-template.id
    version = "$Latest" # Always use the latest version of the launch template
  }
  # ECS adds this tag automatically once the capacity provider is attached;
  # declaring it here stops Terraform from stripping it back out on every apply.
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}