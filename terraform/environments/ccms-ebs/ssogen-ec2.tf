# locals {
#   is_development = local.environment == "development"
# }

data "template_file" "launch-template" {
  template = file("${path.module}/templates/ec2_user_data_ssogen.sh")
  vars = {
    cluster_name       = "${local.application_name}-cluster"
    deploy_environment = local.environment
  }
}

resource "aws_launch_template" "ssogen-ec2-launch-template-primary" {
  count       = local.is-development || local.is-test ? 1 : 0
  name_prefix   = local.application_name
  image_id      = local.application_data.accounts[local.environment].ssogen_ami_id-1
  instance_type = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ssogen
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
    security_groups             = [aws_security_group.ssogen_sg[count.index].id]
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
      { Name = lower(format("%s-%s-launch-template-primary", local.application_name, local.environment)) }
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
      { Name = lower(format("%s-%s-launch-template-primary", local.application_name, local.environment)) }
    )
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-launch-template-primary", local.application_name, local.environment)) }
  )

}

resource "aws_launch_template" "ssogen-ec2-launch-template-secondary" {
  count         = local.is-development || local.is-test ? 1 : 0
  name_prefix   = local.application_name
  image_id      = local.application_data.accounts[local.environment].ssogen_ami_id-2
  instance_type = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ssogen
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
    security_groups             = [aws_security_group.ssogen_sg[count.index].id]
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
      { Name = lower(format("%s-%s-launch-template-secondary", local.application_name, local.environment)) }
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
      { Name = lower(format("%s-%s-launch-template-secondary", local.application_name, local.environment)) }
    )
  }

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-launch-template-secondary", local.application_name, local.environment)) }
  )

}

resource "aws_autoscaling_group" "ssogen-scaling-group-primary" {
  count               = local.is-development || local.is-test ? 1 : 0
  name                = "${local.application_name}-ssogen-auto-scaling-group-primary"
  vpc_zone_identifier = data.aws_subnets.shared-private.ids
  desired_capacity    = local.application_data.accounts[local.environment].ssogen_desired_capacity
  max_size            = local.application_data.accounts[local.environment].ssogen_max_capacity
  min_size            = local.application_data.accounts[local.environment].ssogen_min_capacity

  target_group_arns = [
    aws_lb_target_group.ssogen_internal_tg_ssogen_app.arn,
    aws_lb_target_group.ssogen_internal_tg_ssogen_admin.arn
  ]

   health_check_type         = "EC2"
   health_check_grace_period = 300

   launch_template {
    id      = aws_launch_template.ssogen-ec2-launch-template-primary[count.index].id
    version = "$Latest"
  }

}

resource "aws_autoscaling_group" "ssogen-scaling-group-secondary" {
  count               = local.is-development || local.is-test ? 1 : 0
  name                = "${local.application_name}-ssogen-auto-scaling-group-secondary"
  vpc_zone_identifier = data.aws_subnets.shared-private.ids
  desired_capacity    = local.application_data.accounts[local.environment].ssogen_desired_capacity_secondary
  max_size            = local.application_data.accounts[local.environment].ssogen_max_capacity_secondary
  min_size            = local.application_data.accounts[local.environment].ssogen_min_capacity_secondary

  target_group_arns = [
    aws_lb_target_group.ssogen_internal_tg_ssogen_app.arn,
    aws_lb_target_group.ssogen_internal_tg_ssogen_admin.arn
  ]

   health_check_type         = "EC2"
   health_check_grace_period = 300

   launch_template {
    id      = aws_launch_template.ssogen-ec2-launch-template-primary[count.index].id
    version = "$Latest"
  }

}
# resource "aws_instance" "ec2_ssogen" {
#   count = local.is_development ? local.application_data.accounts[local.environment].ssogen_no_instances : 0

#   instance_type          = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ssogen
#   ami                    = local.application_data.accounts[local.environment]["ssogen_ami_id-${count.index + 1}"]
#   key_name               = aws_key_pair.ssogen[0].key_name
#   vpc_security_group_ids = [aws_security_group.ssogen_sg[0].id]
#   subnet_id              = local.private_subnets[count.index]
#   # monitoring                  = true
#   ebs_optimized               = false
#   associate_public_ip_address = false
#   iam_instance_profile        = aws_iam_instance_profile.ssogen_instance_profile[0].name

#   lifecycle {
#     ignore_changes = [
#       user_data
#     ]
#   }

#   root_block_device {
#     volume_size = 60
#     volume_type = "gp2"
#     encrypted   = true
#     tags = merge(
#       local.tags,
#       { Name = "ec2-ccms-ebs-development-ssogen-${count.index + 1}" },
#       { "instance-role" = local.application_data.accounts[local.environment].instance_role_ssogen },
#       { "instance-scheduling" = local.application_data.accounts[local.environment]["instance-scheduling"] },
#       { backup = "true" }
#     )
#   }

#   # user_data_replace_on_change = true
#   user_data = base64encode(templatefile("./templates/ec2_user_data_ssogen.sh", {
#     hostname = "ssogen-${count.index + 1}"
#   }))

#   metadata_options {
#     http_endpoint = "enabled"
#     http_tokens   = "required"
#   }

#   tags = merge(
#     local.tags,
#     { Name = "ec2-ccms-ebs-development-ssogen-${count.index + 1}" },
#     { "instance-role" = local.application_data.accounts[local.environment].instance_role_ssogen },
#     { "instance-scheduling" = local.application_data.accounts[local.environment]["instance-scheduling"] },
#     { backup = "true" }
#   )

#   depends_on = [aws_security_group.ssogen_sg]
# }
