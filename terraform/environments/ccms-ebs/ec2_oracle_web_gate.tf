resource "aws_launch_template" "webgate_asg_tpl" {
  name_prefix            = lower(format("asg-tpl-%s-%s-Webgate", local.application_name, local.environment))
  image_id               = data.aws_ami.oracle_base_prereqs.id
  instance_type          = local.application_data.accounts[local.environment].ec2_oracle_instance_type_webgate
  key_name               = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg_oracle_base.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.iam_instace_profile_oracle_base.arn
  }

  # AMI ebs mappings from /dev/sd[a-d]
  # root
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_type = "gp3"
      volume_size = 50
      encrypted   = true
      kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    }
  }
  # swap
  block_device_mappings {
    device_name = "/dev/sdb"
    ebs {
      volume_type = "gp3"
      volume_size = 20
      encrypted   = true
      kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    }
  }
  # temp
  block_device_mappings {
    device_name = "/dev/sdc"
    ebs {
      volume_type = "gp3"
      volume_size = 100
      encrypted   = true
      kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    }
  }
  # home
  block_device_mappings {
    device_name = "/dev/sdd"
    ebs {
      volume_type = "gp3"
      volume_size = 100
      encrypted   = true
      kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    }
  }

  # non-AMI mappings start at /dev/sdh
  # u01
  block_device_mappings {
    device_name = "/dev/sdh"
    ebs {
      volume_type = "gp3"
      volume_size = 100
      encrypted   = true
      kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    }
  }
}

resource "aws_autoscaling_group" "webgate_asg" {
  name_prefix      = "webgate-"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1
  vpc_zone_identifier = [data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_b.id,
    data.aws_subnet.private_subnets_c.id
  ]
  target_group_arns = [aws_alb_target_group.webgate_tg.arn]
  launch_template {
    id      = aws_launch_template.webgate_asg_tpl.id
    version = "$Latest"
  }
}


resource "aws_lb" "webgate_alb" {
  name                             = lower(format("alb-%s-%s-Webgate", local.application_name, local.environment))
  internal                         = false
  load_balancer_type               = "application"
  enable_cross_zone_load_balancing = "true"
  # enable_deletion_protection = true
  security_groups = [aws_security_group.ec2_sg_oracle_base.id]
  subnets = [data.aws_subnet.public_subnets_a.id,
    data.aws_subnet.public_subnets_b.id,
    data.aws_subnet.public_subnets_c.id
  ]

  #access_logs {
  #  bucket  = aws_s3_bucket.lb_logs.bucket
  #  prefix  = "webgate-lb"
  #  enabled = true
  #}

  tags = merge(local.tags,
    { Name = lower(format("alb-%s-%s-webgate", local.application_name, local.environment)) }
  )
}

resource "aws_alb_target_group" "webgate_tg" {
  name        = "webgate-targetgroup"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.shared.id
  health_check {
    interval            = 30
    port                = 80
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    path                = "/"
  }

}

/*
resource "aws_security_group" "webgate-alb-sg" {
  #name               = lower(format("sg-%s-%s-Webgate", local.application_name, local.environment)) 
  description = "allow HTTPS to Webgate ALB"
  vpc_id      = data.aws_vpc.shared.id
  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-webgate", local.application_name, local.environment)) }
  )
}
*/
/*
resource "aws_autoscaling_attachment" "webgate_asg_att" {
  autoscaling_group_name = aws_autoscaling_group.webgate_asg.id
  lb_target_group_arn    = aws_alb_target_group.webgate_tg.arn
}
*/



/*
resource "aws_alb_listener" "hhtps_webgate" {
  load_balancer_arn = aws_lb.webgate_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  default_action {
    target_group_arn = aws_alb_target_group.webgate_tg.arn
    type             = "forward"
  }
}
*/
