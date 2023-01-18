

# # Security Groups
# resource "aws_security_group" "webserver_test" {
#   description = "Configure webserver access - ingress should be only from Systems Session Manager (SSM)"
#   name        = "webserver-test"
#   vpc_id      = data.aws_vpc.shared.id

#   tags = {
#     Name = "webserver-test"
#   }
# }

# resource "aws_security_group_rule" "webserver_linux_egress_1" {
#   security_group_id = aws_security_group.webserver_test.id

#   description = "Allow all egress"
#   type        = "egress"
#   from_port   = "0"
#   to_port     = "65535"
#   protocol    = "TCP"
#   cidr_blocks = ["0.0.0.0/0"]
# }

# IAM
data "aws_iam_policy_document" "webserver_test_assume_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "webserver_test_role" {
  name               = "webserver_test_ec2_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.webserver_test_assume_policy_document.json

  tags = {
    Name = "webserver_test_ec2_role"
  }
}

# resource "aws_iam_role" "this" {
#   name                 = "${var.iam_resource_names_prefix}-role-${var.name}"
#   path                 = "/"
#   max_session_duration = "3600"
#   assume_role_policy = jsonencode(
#     {
#       "Version" : "2012-10-17",
#       "Statement" : [
#         {
#           "Effect" : "Allow",
#           "Principal" : {
#             "Service" : "ec2.amazonaws.com"
#           }
#           "Action" : "sts:AssumeRole",
#           "Condition" : {}
#         }
#       ]
#     }
#   )

#   managed_policy_arns = var.instance_profile_policies

#   tags = merge(local.tags, {
#     Name = "${var.iam_resource_names_prefix}-role-${var.name}"
#     }
#   )
# }

resource "aws_iam_instance_profile" "webserver_test_profile" {
  name = "webserver-test-ec2-profile"
  role = aws_iam_role.webserver_test_role.name
  path = "/"
}
# resource "aws_iam_instance_profile" "this" {
#   name = "${var.iam_resource_names_prefix}-profile-${var.name}"
#   role = aws_iam_role.this.name
#   path = "/"
# }


data "aws_ami" "linux_2_image" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "webserver_test_template" {
  name = "webserver_test_template"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 8
      encrypted   = true
    }
  }

  ebs_optimized = true

  iam_instance_profile {
    name = aws_iam_instance_profile.webserver_test_profile.id
  }

  image_id                             = data.aws_ami.linux_2_image.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "t3.micro"

  metadata_options {
    http_endpoint               = "enabled" # defaults to enabled but is required if http_tokens is specified
    http_put_response_hop_limit = 1         # default is 1, value values are 1 through 64
    http_tokens                 = "required"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    device_index                = 0
    security_groups             = [aws_security_group.webserver.id]
    subnet_id                   = data.aws_subnet.private_subnets_a.id
    delete_on_termination       = true
  }

  placement {
    availability_zone = "${local.region}a"
  }

  tag_specifications {
    resource_type = "instance"

    tags = { Name = "webserver_test" }
  }
}
# resource "aws_launch_template" "this" {
#   name                                 = var.name
#   disable_api_termination              = var.instance.disable_api_termination
#   ebs_optimized                        = data.aws_ec2_instance_type.this.ebs_optimized_support == "unsupported" ? false : true
#   image_id                             = data.aws_ami.this.id
#   instance_initiated_shutdown_behavior = "terminate"
#   instance_type                        = var.instance.instance_type
#   key_name                             = var.instance.key_name
#   update_default_version               = true

#   # NOTE: ephemeral devices have an empty ebs {} block, hence the null checks
#   dynamic "block_device_mappings" {
#     for_each = local.ebs_volumes
#     content {
#       device_name  = block_device_mappings.key
#       no_device    = lookup(block_device_mappings.value, "no_device", null)
#       virtual_name = lookup(block_device_mappings.value, "virtual_name", null)
#       ebs {
#         delete_on_termination = block_device_mappings.value.type != null ? true : null
#         encrypted             = block_device_mappings.value.type != null ? true : null
#         kms_key_id            = block_device_mappings.value.type != null ? data.aws_kms_key.by_alias.arn : null

#         iops        = try(block_device_mappings.value.iops > 0, false) ? block_device_mappings.value.iops : null
#         throughput  = try(block_device_mappings.value.throughput > 0, false) ? block_device_mappings.value.throughput : null
#         volume_size = block_device_mappings.value.size
#         volume_type = block_device_mappings.value.type
#       }
#     }
#   }

#   iam_instance_profile {
#     arn = aws_iam_instance_profile.this.arn
#   }

#   metadata_options {
#     #checkov:skip=CKV_AWS_79:"We have to use version 1 in some cases"
#     http_endpoint = coalesce(var.instance.metadata_endpoint_enabled, "enabled")
#     #tfsec:ignore:aws-ec2-enforce-http-token-imds tfsec:ignore:aws-ec2-enforce-launch-config-http-token-imds
#     http_tokens = coalesce(var.instance.metadata_options_http_tokens, "required")
#   }

#   monitoring {
#     enabled = coalesce(var.instance.monitoring, true)
#   }

#   network_interfaces {
#     associate_public_ip_address = false
#     security_groups             = var.instance.vpc_security_group_ids
#     delete_on_termination       = true
#   }

#   dynamic "private_dns_name_options" {
#     for_each = var.instance.private_dns_name_options != null ? [var.instance.private_dns_name_options] : []
#     content {
#       enable_resource_name_dns_aaaa_record = private_dns_name_options.value.enable_resource_name_dns_aaaa_record
#       enable_resource_name_dns_a_record    = private_dns_name_options.value.enable_resource_name_dns_a_record
#       hostname_type                        = private_dns_name_options.value.hostname_type
#     }
#   }

#   user_data = length(data.cloudinit_config.this) == 0 ? local.user_data_raw : data.cloudinit_config.this[0].rendered

#   tag_specifications {
#     resource_type = "instance"
#     tags = merge(local.tags, {
#       Name = var.name
#     })
#   }

#   # all volumes will get tagged with the same name
#   tag_specifications {
#     resource_type = "volume"
#     tags = merge(local.tags, {
#       Name = "${var.name}-volume"
#     })
#   }

#   lifecycle {
#     # description and tags will be updated by Image Builder
#     ignore_changes = [
#       description,
#       tags["CreatedBy"],
#       tags_all["CreatedBy"],
#     ]
#   }
# }

resource "aws_autoscaling_group" "webserver_test" { # should have changed the asg to be the same now
  launch_template {
    id      = aws_launch_template.webserver_test_template.id
    version = "$Default"
  }
  name                      = "webserver_test"
  availability_zones        = ["${local.region}a"]
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  termination_policies      = ["OldestInstance"]

  tag {
    key                 = "Name"
    value               = "webserver_test"
    propagate_at_launch = true
  }
}

####### looks the same
resource "aws_autoscaling_schedule" "webserver_test_scale_down" {
  scheduled_action_name  = "webserver_test_scale_down"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "0 20 * * *" # 20.00 UTC time or 21.00 London time
  autoscaling_group_name = aws_autoscaling_group.webserver_test.name
}

resource "aws_autoscaling_schedule" "webserver_test_scale_up" {
  scheduled_action_name  = "webserver_test_scale_up"
  min_size               = 1
  max_size               = 1
  desired_capacity       = 1
  recurrence             = "0 5 * * *" # 5.00 UTC time or 6.00 London time
  autoscaling_group_name = aws_autoscaling_group.webserver_test.name
}
