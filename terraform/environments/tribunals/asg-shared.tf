resource "aws_launch_template" "tribunals-all-lt" {
  name_prefix   = "tribunals-all"
  image_id      = "ami-0d20b6fc5007adcb3"
  instance_type = "m5.large"

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 80
    }
  }
  ebs_optimized = true

  network_interfaces {
    subnet_id = data.aws_subnets.shared-public.ids
  }

  vpc_security_group_ids = [aws_security_group.tribunals_lb_sc.id]

  user_data = filebase64("ec2-shared-user-data.sh")
}

resource "aws_autoscaling_group" "tribunals-all-asg" {
  availability_zones = ["eu-west-2a"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = "${aws_launch_template.tribunals-all-lt.id}"
    version = "$Latest"
  }
}