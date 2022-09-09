module "lb-access-logs-enabled" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer"

  vpc_all                    = local.vpc_all
  application_name           = local.application_name
  public_subnets             = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  loadbalancer_ingress_rules = local.loadbalancer_ingress_rules
  loadbalancer_egress_rules  = local.loadbalancer_ingress_rules
  tags                       = local.tags
  account_number             = local.environment_management.account_ids[terraform.workspace]
  region                     = local.app_data.accounts[local.environment].region
  enable_deletion_protection = false
  idle_timeout               = 60
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = module.lb-access-logs-enabled.load_balancer
  port              = "80"
  protocol          = "HTTP"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instance_target_group.arn
  }
}

resource "aws_lb_listener_rule" "forwarding_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instance_target_group.arn
  }

  condition {
    host_header {
      values = ["my-service.*.terraform.io"]
    }
  }
}

resource "aws_lb_target_group" "instance_target_group" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.shared.id
}

/* module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs"

  subnet_set_name         = local.subnet_set_name
  vpc_all                 = local.vpc_all
  app_name                = local.application_name
  container_instance_type = local.app_data.accounts[local.environment].container_instance_type
  environment             = local.environment
  ami_image_id            = local.app_data.accounts[local.environment].ami_image_id
  instance_type           = local.app_data.accounts[local.environment].instance_type
  user_data               = base64encode(data.template_file.user_data.rendered)
  key_name                = local.app_data.accounts[local.environment].key_name
  task_definition         = data.template_file.task_definition.rendered
  ec2_desired_capacity    = local.app_data.accounts[local.environment].ec2_desired_capacity
  ec2_max_size            = local.app_data.accounts[local.environment].ec2_max_size
  ec2_min_size            = local.app_data.accounts[local.environment].ec2_min_size
  container_cpu           = local.app_data.accounts[local.environment].container_cpu
  container_memory        = local.app_data.accounts[local.environment].container_memory
  task_definition_volume  = local.app_data.accounts[local.environment].task_definition_volume
  network_mode            = local.app_data.accounts[local.environment].network_mode
  server_port             = local.app_data.accounts[local.environment].server_port
  app_count               = local.app_data.accounts[local.environment].app_count
  tags_common             = local.tags

  depends_on = [aws_ecr_repository.ecr_repo, resource.aws_lb_listener.alb_listener]
}

data "template_file" "user_data" {
  template = file("${module.path}/node-userdata.sh")

  vars {
    APP_NAME = local.application_name
  }
} */
