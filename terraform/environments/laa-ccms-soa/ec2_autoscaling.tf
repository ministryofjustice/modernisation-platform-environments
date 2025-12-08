# EC2 Autoscaling group

#--Managed
resource "aws_autoscaling_group" "cluster-scaling-group-managed" {
  name                = "${local.application_data.accounts[local.environment].app_name}-auto-scaling-group-managed"
  vpc_zone_identifier = data.aws_subnets.shared-private.ids
  desired_capacity    = local.application_data.accounts[local.environment].managed_ec2_desired_capacity
  max_size            = local.is-production ? 7 : 4
  min_size            = 1

  launch_template {
    id      = aws_launch_template.ec2-launch-template-managed.id
    version = "$Latest"
  }
  tag {
    key                 = "instance-scheduling"
    value               = "skip-scheduling"
    propagate_at_launch = true
  }
  depends_on = [
    aws_efs_file_system.storage,
    aws_db_instance.soa_db
  ]
}

#--Admin
resource "aws_autoscaling_group" "cluster-scaling-group-admin" {
  name                = "${local.application_data.accounts[local.environment].app_name}-auto-scaling-group-admin"
  vpc_zone_identifier = data.aws_subnets.shared-private.ids
  desired_capacity    = local.application_data.accounts[local.environment].admin_ec2_desired_capacity
  max_size            = 1
  min_size            = 1

  launch_template {
    id      = aws_launch_template.ec2-launch-template-admin.id
    version = "$Latest"
  }
  tag {
    key                 = "instance-scheduling"
    value               = "skip-scheduling"
    propagate_at_launch = true
  }
  depends_on = [
    aws_efs_file_system.storage,
    aws_db_instance.soa_db
  ]
}

# EC2 launch template - settings to use for new EC2s added to the group
# Note - when updating this you will need to manually terminate the EC2s
# so that the autoscaling group creates new ones using the new launch template

resource "aws_launch_template" "ec2-launch-template-managed" {
  name          = "${local.application_data.accounts[local.environment].app_name}-launch-template-managed"
  image_id      = local.application_data.accounts[local.environment].managed_ami_image_id
  instance_type = local.application_data.accounts[local.environment].managed_ec2_instance_type
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
    delete_on_termination       = false
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = data.aws_kms_alias.ebs.target_key_arn #--Instances would not book with a CMK and time to debug was not available.
      volume_size           = 30                                    #  Ideally this needs to be debugged and migrated on to a CMK! - AW
      volume_type           = "gp2"
      iops                  = 0
    }
  }

  user_data = base64encode(data.template_file.launch-template-managed.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_data.accounts[local.environment].app_name}-ecs-cluster-managed" },
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_data.accounts[local.environment].app_name}-ecs-cluster-managed" },
    )
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_data.accounts[local.environment].app_name}-ecs-cluster-template-managed" },
  )
}

# Admin server launch template
resource "aws_launch_template" "ec2-launch-template-admin" {
  name          = "${local.application_data.accounts[local.environment].app_name}-launch-template-admin"
  image_id      = local.application_data.accounts[local.environment].admin_ami_image_id
  instance_type = local.application_data.accounts[local.environment].admin_ec2_instance_type
  #key_name      = local.application_data.accounts[local.environment].admin_ec2_key_name
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
    delete_on_termination       = false
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = data.aws_kms_alias.ebs.target_key_arn #--TEMPORARY. SHOULD USE A CMK. AW
      volume_size           = 30
      volume_type           = "gp2"
      iops                  = 0
    }
  }

  user_data = base64encode(data.template_file.launch-template-admin.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_data.accounts[local.environment].app_name}-ecs-cluster-admin" },
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      local.tags,
      { "Name" = "${local.application_data.accounts[local.environment].app_name}-ecs-cluster-admin" },
    )
  }

  tags = merge(
    local.tags,
    { "Name" = "${local.application_data.accounts[local.environment].app_name}-ecs-cluster-template-admin" },
  )
}

# Datafile to generate the user-data for the EC2
data "template_file" "launch-template-managed" {
  template = file("${path.module}/templates/user-data.sh")
  vars = {
    cluster_name       = "${local.application_data.accounts[local.environment].app_name}-cluster"
    efs_id             = aws_efs_file_system.storage.id
    server             = "managed"
    inbound_bucket     = local.application_data.accounts[local.environment].inbound_s3_bucket_name
    outbound_bucket    = local.application_data.accounts[local.environment].outbound_s3_bucket_name
    deploy_environment = local.environment
  }
}

data "template_file" "launch-template-admin" {
  template = file("${path.module}/templates/user-data.sh")
  vars = {
    cluster_name       = "${local.application_data.accounts[local.environment].app_name}-cluster"
    efs_id             = aws_efs_file_system.storage.id
    server             = "admin"
    inbound_bucket     = local.application_data.accounts[local.environment].inbound_s3_bucket_name
    outbound_bucket    = local.application_data.accounts[local.environment].outbound_s3_bucket_name
    deploy_environment = local.environment
  }
}
