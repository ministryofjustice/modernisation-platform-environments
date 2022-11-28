resource "aws_launch_template" "this" {
  name                                 = var.name
  disable_api_termination              = var.instance.disable_api_termination
  ebs_optimized                        = data.aws_ec2_instance_type.this.ebs_optimized_support == "unsupported" ? false : true
  image_id                             = data.aws_ami.this.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.instance.instance_type
  key_name                             = var.instance.key_name
  update_default_version               = true

  # NOTE: ephemeral devices have an empty ebs {} block, hence the null checks
  dynamic "block_device_mappings" {
    for_each = local.ebs_volumes
    content {
      device_name  = block_device_mappings.key
      no_device    = block_device_mappings.value.no_device
      virtual_name = block_device_mappings.value.virtual_name
      ebs {
        delete_on_termination = block_device_mappings.value.type != null ? true : null
        encrypted             = block_device_mappings.value.type != null ? true : null
        kms_key_id            = block_device_mappings.value.type != null ? data.aws_kms_key.by_alias.arn : null

        iops        = try(block_device_mappings.value.iops > 0, false) ? block_device_mappings.value.iops : null
        throughput  = try(block_device_mappings.value.throughput > 0, false) ? block_device_mappings.value.throughput : null
        volume_size = block_device_mappings.value.size
        volume_type = block_device_mappings.value.type
      }
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.this.arn
  }

  metadata_options {
    #checkov:skip=CKV_AWS_79:"We have to use version 1 in some cases"
    http_endpoint = coalesce(var.instance.metadata_endpoint_enabled, "disabled")
    #tfsec:ignore:aws-ec2-enforce-http-token-imds tfsec:ignore:aws-ec2-enforce-launch-config-http-token-imds
    http_tokens = coalesce(var.instance.metadata_options_http_tokens, "required")
  }

  monitoring {
    enabled = coalesce(var.instance.monitoring, true)
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.instance.vpc_security_group_ids
    delete_on_termination       = true
  }

  dynamic "private_dns_name_options" {
    for_each = var.instance.private_dns_name_options != null ? [var.instance.private_dns_name_options] : []
    content {
      enable_resource_name_dns_aaaa_record = private_dns_name_options.value.enable_resource_name_dns_aaaa_record
      enable_resource_name_dns_a_record    = private_dns_name_options.value.enable_resource_name_dns_a_record
      hostname_type                        = private_dns_name_options.value.hostname_type
    }
  }

  user_data = length(data.cloudinit_config.this) == 0 ? local.user_data_raw : data.cloudinit_config.this[0].rendered

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags, {
      Name = var.name
    })
  }

  # all volumes will get tagged with the same name
  tag_specifications {
    resource_type = "volume"
    tags = merge(local.tags, {
      Name = "${var.name}-volume"
    })
  }

  lifecycle {
    # description and tags will be updated by Image Builder
    ignore_changes = [
      description,
      tags["CreatedBy"],
      tags_all["CreatedBy"],
    ]
  }
}

resource "aws_autoscaling_group" "this" {
  name                      = var.name
  desired_capacity          = var.autoscaling_group.desired_capacity
  max_size                  = var.autoscaling_group.max_size
  min_size                  = var.autoscaling_group.min_size
  health_check_grace_period = var.autoscaling_group.health_check_grace_period
  health_check_type         = var.autoscaling_group.health_check_type
  force_delete              = var.autoscaling_group.force_delete
  termination_policies      = var.autoscaling_group.termination_policies
  target_group_arns         = var.autoscaling_group.target_group_arns
  vpc_zone_identifier       = [data.aws_subnet.this.id]
  wait_for_capacity_timeout = var.autoscaling_group.wait_for_capacity_timeout

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Default"
  }

  dynamic "initial_lifecycle_hook" {
    for_each = var.autoscaling_group.initial_lifecycle_hooks != null ? var.autoscaling_group.initial_lifecycle_hooks : {}
    content {
      name                 = "${var.name}-${initial_lifecycle_hook.key}"
      default_result       = initial_lifecycle_hook.value.default_result
      heartbeat_timeout    = initial_lifecycle_hook.value.heartbeat_timeout
      lifecycle_transition = initial_lifecycle_hook.value.lifecycle_transition
    }
  }

  dynamic "instance_refresh" {
    for_each = var.autoscaling_group.instance_refresh != null ? [var.autoscaling_group.instance_refresh] : []

    content {
      strategy = instance_refresh.value.strategy

      preferences {
        min_healthy_percentage = instance_refresh.value.min_healthy_percentage
        instance_warmup        = instance_refresh.value.instance_warmup
      }
    }
  }

  dynamic "warm_pool" {
    for_each = var.autoscaling_group.warm_pool != null ? [var.autoscaling_group.warm_pool] : []

    content {
      pool_state                  = warm_pool.value.pool_state
      min_size                    = warm_pool.value.min_size
      max_group_prepared_capacity = coalesce(warm_pool.value.max_group_prepared_capacity, var.autoscaling_group.max_size)

      instance_reuse_policy {
        reuse_on_scale_in = warm_pool.value.reuse_on_scale_in
      }
    }
  }

  dynamic "tag" {
    for_each = merge(local.tags, {
      Name = var.name
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  depends_on = [
    aws_launch_template.this
  ]
}

resource "aws_autoscaling_schedule" "this" {
  for_each = var.autoscaling_schedules

  scheduled_action_name  = "${var.name}-${each.key}"
  min_size               = coalesce(each.value.min_size, var.autoscaling_group.min_size)
  max_size               = coalesce(each.value.max_size, var.autoscaling_group.max_size)
  desired_capacity       = coalesce(each.value.desired_capacity, var.autoscaling_group.desired_capacity)
  recurrence             = each.value.recurrence
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "random_password" "this" {
  for_each = var.ssm_parameters != null ? var.ssm_parameters : {}

  length  = each.value.random.length
  special = lookup(each.value.random, "special", null)
}

resource "aws_ssm_parameter" "this" {
  for_each = var.ssm_parameters != null ? var.ssm_parameters : {}

  name        = "/${var.ssm_parameters_prefix}${var.name}/${each.key}"
  description = each.value.description
  type        = "SecureString"
  value       = random_password.this[each.key].result

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-${each.key}"
    }
  )
}

resource "aws_iam_role" "this" {
  name                 = "${var.iam_resource_names_prefix}-role-${var.name}"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )

  managed_policy_arns = var.instance_profile_policies

  tags = merge(local.tags, {
    Name = "${var.iam_resource_names_prefix}-role-${var.name}"
    }
  )
}

data "aws_iam_policy_document" "asm_parameter" {
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter"]
    #tfsec:ignore:aws-iam-no-policy-wildcards: acccess scoped to parameter path
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.id}:parameter/${var.ssm_parameters_prefix}${var.name}/*"]
  }
}

resource "aws_iam_role_policy" "asm_parameter" {
  count  = var.ssm_parameters != null ? 1 : 0
  name   = "asm-parameter-access-${var.name}"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.asm_parameter.json
}

data "aws_iam_policy_document" "lifecycle_hooks" {
  statement {
    sid     = "TriggerInstanceLifecycleHooks"
    effect  = "Allow"
    actions = ["autoscaling:CompleteLifecycleAction"]
    #tfsec:ignore:aws-iam-no-policy-wildcards: this needs to be created before the autoscaling group, therefore the ASG ID needs to be wildcarded
    resources = [
      "arn:aws:autoscaling:${var.region}:${data.aws_caller_identity.current.id}:autoScalingGroup:*:autoScalingGroupName/${var.name}"
    ]
  }
}

resource "aws_iam_role_policy" "lifecycle_hooks" {
  count  = var.autoscaling_group.initial_lifecycle_hooks != null ? 1 : 0
  name   = "trigger-instance-lifecycle-hooks-${var.name}"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.lifecycle_hooks.json
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.iam_resource_names_prefix}-profile-${var.name}"
  role = aws_iam_role.this.name
  path = "/"
}
