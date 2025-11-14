data "template_file" "user_data" {
  template = file("${path.module}/scripts/${var.app_key}.ps1")

  vars = var.env_vars
}

resource "aws_iam_role" "instance_role" {
  count = var.enable_compute_node ? 1 : 0

  name = "${var.name}-windows-role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Principal = { Service = "ec2.amazonaws.com" },
        Effect    = "Allow",
      }
    ]
  })
}

resource "aws_iam_instance_profile" "instance_profile" {
  count = var.enable_compute_node ? 1 : 0

  name = "${var.name}-windows-profile"
  role = aws_iam_role.instance_role[0].name
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  count      = var.enable_compute_node ? 1 : 0
  role       = aws_iam_role.instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each   = var.enable_compute_node ? toset(var.policies) : toset([])
  role       = aws_iam_role.instance_role[0].id
  policy_arn = each.value
}

resource "aws_security_group" "windows_sg" {
  count       = var.enable_compute_node ? 1 : 0
  name        = "${var.name}-windows-sg"
  description = var.description
  vpc_id      = var.vpc
  tags        = var.tags
}

resource "aws_security_group_rule" "windows_ingress" {
  for_each          = var.enable_compute_node ? var.ec2_sec_rules : {}
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.windows_sg[0].id
  type              = "ingress"
  cidr_blocks       = var.cidr
  description       = "Allow windows ingress from ${each.value.from_port} to ${each.value.to_port} via ${each.value.protocol}"
}

resource "aws_security_group_rule" "windows_egress" {
  count             = var.enable_compute_node ? 1 : 0
  from_port         = 0
  to_port           = 0
  protocol          = -1
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.windows_sg[0].id
  description       = "Allow windows egress"
}

resource "aws_launch_template" "windows_template" {
  # checkov:skip=CKV_AWS_79: IMDSv1 is required for compatibility with legacy systems
  count = var.enable_compute_node ? 1 : 0

  name_prefix   = "${var.name}-win-template"
  image_id      = var.ami_image_id
  instance_type = var.ec2_instance_type

  key_name = var.key_name

  block_device_mappings {
    device_name = "xvda"

    ebs {
      volume_size           = var.ebs_size
      volume_type           = "gp3"
      delete_on_termination = var.ebs_delete_on_termination
      encrypted             = var.ebs_encrypted
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile[0].name
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    device_index                = 0
    subnet_id                   = var.subnet_ids
    security_groups             = [aws_security_group.windows_sg[0].id]
    delete_on_termination       = true
  }

  # user_data = base64encode(file("${path.module}/scripts/${var.app_key}.ps1"))
  user_data = base64encode(data.template_file.user_data.rendered)

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }
}

resource "aws_autoscaling_group" "windows_asg" {
  count = var.enable_compute_node ? 1 : 0

  launch_template {
    id      = aws_launch_template.windows_template[0].id
    version = aws_launch_template.windows_template[0].latest_version
  }

  availability_zones        = ["${var.aws_region}a"]
  name                      = "${var.name}-windows-asg"
  min_size                  = 1
  max_size                  = 1
  health_check_type         = "EC2"
  health_check_grace_period = 300
  termination_policies      = ["OldestInstance"]

  tag {
    key                 = "type"
    value               = "windows_compute_node"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    triggers = ["launch_template", "desired_capacity"] # You can add any argument from ASG here, if those has changes, ASG Instance Refresh will trigger
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
