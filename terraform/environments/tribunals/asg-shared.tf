locals {
  app_name                  = "tribunals-shared"
  instance_role_name        = join("-", [local.app_name, "ec2-instance-role"])
  instance_profile_name     = join("-", [local.app_name, "ec2-instance-profile"])
  tags_common               = local.tags
}

resource "aws_launch_template" "tribunals-all-lt" {
  name_prefix   = "tribunals-all"
  image_id      = "ami-0d20b6fc5007adcb3"
  instance_type = "m5.large"
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile
  }

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 80
    }
  }
  ebs_optimized = true

  network_interfaces {
    device_index                = 0
    security_groups             = [aws_security_group.tribunals_lb_sc.id]
    subnet_id                   = data.aws_subnet.public_subnets_a.id
    delete_on_termination       = true
  }

  user_data = filebase64("ec2-shared-user-data.sh")
}

resource "aws_autoscaling_group" "tribunals-all-asg" {
  vpc_zone_identifier = sort(data.aws_subnets.shared-private.ids)
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = "${aws_launch_template.tribunals-all-lt.id}"
    version = "$Latest"
  }
}

# The role is added to the ec2 instance profile which is added to the launch template
resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2-shared-instance-role"
  tags = merge(
  local.tags,
  {
    Name = local.instance_role_name
  }
  )
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = local.instance_profile_name
  role = aws_iam_role.ec2_instance_role.name
  tags = merge(
  local.tags_common,
  {
    Name = local.instance_profile_name
  }
  )
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_instance_role
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}