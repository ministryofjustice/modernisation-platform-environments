data "aws_caller_identity" "current" {}

data "template_file" "user_data" {
  template = file("${path.module}/scripts/${var.app_key}.sh")

  vars = var.env_vars
}

# Keypair for ec2-user
resource "tls_private_key" "ec2-user" {
  count = var.enable_compute_node ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2-user" {
  count = var.enable_compute_node ? 1 : 0

  key_name   = "${var.name}-keypair"
  public_key = tls_private_key.ec2-user[0].public_key_openssh
  tags       = var.tags
}

# Build the security group for the EC2
resource "aws_security_group" "ec2_sec_group" {
  count = var.enable_compute_node ? 1 : 0

  name        = "${var.name}-sgroup"
  description = var.description
  vpc_id      = var.vpc
  tags        = var.tags
}

resource "aws_security_group_rule" "ingress_traffic" {
  for_each = var.enable_compute_node ? var.ec2_sec_rules : {}

  description       = format("Traffic for %s %d", each.value.protocol, each.value.from_port)
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.ec2_sec_group[0].id
  to_port           = each.value.to_port
  type              = "ingress"
  cidr_blocks       = var.cidr
}

# Needs revision for Egress after POC
resource "aws_security_group_rule" "egress_traffic" {
  #checkov:skip=CKV_AWS_23: "Ensure every security group and rule has a description"
  count = var.enable_compute_node ? 1 : 0

  security_group_id = aws_security_group.ec2_sec_group[0].id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_launch_template" "ec2_template" {
  count = var.enable_compute_node ? 1 : 0

  name = "${var.name}_template"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.ebs_size
      encrypted             = var.ebs_encrypted
      delete_on_termination = var.ebs_delete_on_termination
    }
  }

  ebs_optimized = var.ebs_optimized

  iam_instance_profile {
    name = "${var.name}-profile"
  }

  image_id                             = var.ami_image_id
  instance_initiated_shutdown_behavior = var.ec2_terminate_behavior
  instance_type                        = var.ec2_instance_type
  key_name                             = aws_key_pair.ec2-user[0].key_name
  metadata_options {
    http_endpoint               = "enabled" # defaults to enabled but is required if http_tokens is specified
    http_put_response_hop_limit = 1         # default is 1, value values are 1 through 64
    http_tokens                 = "required"
  }

  monitoring {
    enabled = var.monitoring
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    device_index                = 0
    security_groups             = [aws_security_group.ec2_sec_group[0].id]
    subnet_id                   = var.subnet_ids
    delete_on_termination       = true
  }

  placement {
    availability_zone = "${var.aws_region}a"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }

  user_data = base64encode(data.template_file.user_data.rendered)
}

resource "aws_autoscaling_group" "bastion_linux_daily" {
  count = var.enable_compute_node ? 1 : 0

  launch_template {
    id      = aws_launch_template.ec2_template[0].id
    version = aws_launch_template.ec2_template[0].latest_version
  }
  availability_zones        = ["${var.aws_region}a"]
  name                      = "${var.name}_asg"
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  termination_policies      = ["OldestInstance"]

  tag {
    key                 = "type"
    value               = "aws_autoscaling_group"
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

resource "aws_autoscaling_schedule" "bastion_linux_scale_down" {
  count = var.enable_compute_node && var.scale_down ? 1 : 0

  scheduled_action_name  = "${var.name}_scaledown"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 19 * * *" # 19.00 UTC time or 20.00 London time
  autoscaling_group_name = aws_autoscaling_group.bastion_linux_daily[0].name
}

resource "aws_autoscaling_schedule" "bastion_linux_scale_up" {
  count = var.enable_compute_node && var.scale_down ? 1 : 0

  scheduled_action_name  = "${var.name}_scaleup"
  min_size               = 1
  max_size               = 1
  desired_capacity       = 1
  recurrence             = "0 7 * * *"
  autoscaling_group_name = aws_autoscaling_group.bastion_linux_daily[0].name
}