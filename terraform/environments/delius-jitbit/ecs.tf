#tfsec:ignore:aws-ec2-no-public-egress-sgr
#tfsec:ignore:aws-cloudwatch-log-group-customer-key
module "ecs" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs?ref=654c2b2"

  subnet_set_name         = local.subnet_set_name
  vpc_all                 = local.vpc_all
  app_name                = local.application_name
  container_instance_type = local.application_data.accounts[local.environment].container_instance_type
  ami_image_id            = data.aws_ami.ecs_ami.id
  instance_type           = local.application_data.accounts[local.environment].instance_type
  user_data               = base64encode(data.template_file.launch-template.rendered)
  key_name                = local.application_data.accounts[local.environment].key_name
  task_definition         = local.task_definition
  ec2_desired_capacity    = local.application_data.accounts[local.environment].ec2_desired_capacity
  ec2_max_size            = local.application_data.accounts[local.environment].ec2_max_size
  ec2_min_size            = local.application_data.accounts[local.environment].ec2_min_size
  container_cpu           = local.application_data.accounts[local.environment].container_cpu
  container_memory        = local.application_data.accounts[local.environment].container_memory
  task_definition_volume  = local.application_data.accounts[local.environment].task_definition_volume
  network_mode            = local.application_data.accounts[local.environment].network_mode
  server_port             = local.application_data.accounts[local.environment].server_port
  app_count               = local.application_data.accounts[local.environment].app_count
  tags_common             = local.tags
  lb_tg_name              = aws_lb_target_group.target_group.name
  ec2_ingress_rules       = local.ec2_ingress_rules
  ec2_egress_rules        = local.ec2_egress_rules

  # removed a depends on here on the loadbalancer listener - if plan failing, try re-add
  # adding a module dependson forced terraform to plan the recreation of resources in the module
  # e.g. the ec2 cluster security group

  # depends_on = [aws_lb_listener.listener]
}


data "template_file" "launch-template" {
  template = file("templates/user-data.txt")
  vars = {
    cluster_name = local.application_name
    environment  = local.environment
  }
}

resource "aws_key_pair" "jitbit-ec2" {
  key_name   = "jitbit-ec2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD1G18ojDkMZuCDmlTdOGy50g9MYKSkwFF6Mu5v4ubH+ST9T8gUoYDO7U0DlP5q5APG95V7AavZve51SU5cgEQ0THaDACWPi96V95gQUWt4gGoZ5C8nKvqMJgzD+yG4z6bbK5fL7kmWxUEWUdjXzw/lwSI6jr2atmxVB8rdMug6ckKo0z7KZ8S/8ZjmJpEzhALG8/0GISYpLKCY0qlGPm6oUGi8NcUtRcU0AS67praV8LVAqMgLLGrJXu4oQBxb4oYu3xB3xKEQmtT4G57S8eAzb9J5DM7WOTZXXOOIqZuiod6x78h077SKFYmtN6ruuapbg0qyIzkmhNLCSlvPdtdWr/jxG3xCynvoqJeFIHWlv9TA3Rq18dNAAitQxZRedG/hQ1Db/CtIi63lLxq8Wj4qRvgVhAeJKQKlSJPlztZtd240b0raVtBZ0mPaHo3Y0+tJCGZ9NSoenG7Fqadosi/zYs2s9S2vVPlypo+a1YBlAv0uhAk3u1wzbTwcqXE10g8= sebastian.norris@MJ003357"
}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
