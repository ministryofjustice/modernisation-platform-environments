###########################################################################################
#------------------------Comment out file if not required----------------------------------
###########################################################################################


# module "ecs-cluster" {
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=b00647922a9204a99b023ac884440162e2b51b66" #v4.3.0
#   name   = local.ecs_application_name
#   tags   = local.tags
# }

# module "service" {
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//service?ref=b00647922a9204a99b023ac884440162e2b51b66" #v4.3.0

#   container_definitions = templatefile("${path.module}/templates/task_definition.json.tftpl", {})
#   cluster_arn           = module.ecs-cluster.ecs_cluster_arn
#   name                  = "${local.ecs_application_name}-task_definition_volume"

#   task_cpu    = local.application_data.accounts[local.environment].container_cpu
#   task_memory = local.application_data.accounts[local.environment].container_memory

#   service_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.ecs_application_name}-ecs-service-role"
#   task_role_arn      = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.ecs_application_name}-ecs-task-role"
#   task_exec_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.ecs_application_name}-ecs-task-execution-role"

#   health_check_grace_period_seconds = "300"

#   service_load_balancers = [
#     {
#       target_group_arn = aws_lb_target_group.ecs_target_group.arn
#       container_name   = local.ecs_application_name
#       container_port   = 80
#     }
#   ]

#   subnets = [
#     data.aws_subnet.private_subnets_a.id,
#     data.aws_subnet.private_subnets_b.id,
#     data.aws_subnet.private_subnets_c.id
#   ]

#   security_groups = [aws_security_group.cluster_ec2.id]

#   ignore_changes = false

#   tags = local.tags
# }

# locals {
#   ecs_application_name = "example-app"
#   # Build EC2 ingress and egress rules
#   ec2_ingress_rules = {
#     "cluster_ec2_lb_ingress" = {
#       description = "Cluster EC2 ingress rule"
#       from_port   = 22
#       to_port     = 22
#       protocol    = "tcp"
#       cidr_blocks = [
#       data.aws_vpc.shared.cidr_block]
#       security_groups = []
#     }
#     "cluster_ec2_lb_ingress_2" = {
#       description = "Cluster EC2 ingress rule 2"
#       from_port   = 80
#       to_port     = 80
#       protocol    = "tcp"
#       cidr_blocks = [
#       data.aws_vpc.shared.cidr_block]
#       security_groups = []
#     }
#   }
#   ec2_egress_rules = {
#     "cluster_ec2_lb_egress" = {
#       description     = "Cluster EC2 loadbalancer egress rule"
#       from_port       = 443
#       to_port         = 443
#       protocol        = "tcp"
#       cidr_blocks     = ["0.0.0.0/0"]
#       security_groups = []
#     }
#   }
#   # Build loadbalancer ingress and egress rules
#   ecs_loadbalancer_ingress_rules = {
#     "cluster_ec2_lb_ingress" = {
#       description     = "Cluster EC2 loadbalancer ingress rule"
#       from_port       = 80
#       to_port         = 80
#       protocol        = "tcp"
#       cidr_blocks     = [data.aws_vpc.shared.cidr_block]
#       security_groups = []
#     },
#     "cluster_ec2_bastion_ingress" = {
#       description     = "Cluster EC2 bastion ingress rule"
#       from_port       = 3389
#       to_port         = 3389
#       protocol        = "tcp"
#       cidr_blocks     = [data.aws_vpc.shared.cidr_block]
#       security_groups = []
#     }
#   }

#   ecs_loadbalancer_egress_rules = {
#     "cluster_ec2_lb_egress" = {
#       description     = "Cluster EC2 loadbalancer egress rule"
#       from_port       = 443
#       to_port         = 443
#       protocol        = "tcp"
#       cidr_blocks     = ["0.0.0.0/0"]
#       security_groups = []
#     }
#   }
# }

# # Load balancer build using the module
# module "ecs_lb_access_logs_enabled" {
#   source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer?ref=6f59e1ce47df66bc63ee9720b7c58993d1ee64ee" #v4.0.0
#   providers = {
#     # Here we use the default provider for the S3 bucket module, buck replication is disabled but we still
#     # Need to pass the provider to the S3 bucket module
#     aws.bucket-replication = aws
#   }
#   vpc_all = "${local.vpc_name}-${local.environment}"
#   #existing_bucket_name               = "my-bucket-name"
#   force_destroy_bucket       = true # enables destruction of logging bucket
#   application_name           = local.ecs_application_name
#   public_subnets             = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
#   loadbalancer_ingress_rules = local.ecs_loadbalancer_ingress_rules
#   loadbalancer_egress_rules  = local.ecs_loadbalancer_egress_rules
#   tags                       = local.tags
#   account_number             = local.environment_management.account_ids[terraform.workspace]
#   region                     = "eu-west-2"
#   enable_deletion_protection = false
#   idle_timeout               = 60
# }

# resource "random_id" "ecs_target_group" {
#   byte_length = 4
# }

# //# Create the target group
# resource "aws_lb_target_group" "ecs_target_group" {
#   name                 = "${local.ecs_application_name}-tg-ecs-${random_id.ecs_target_group.hex}"
#   port                 = local.application_data.accounts[local.environment].server_port
#   protocol             = "HTTP"
#   vpc_id               = data.aws_vpc.shared.id
#   target_type          = "ip"
#   deregistration_delay = 30

#   stickiness {
#     type = "lb_cookie"

#   }
#   #checkov:skip=CKV_AWS_261: "health_check defined below, but not picked up"
#   health_check {
#     healthy_threshold   = "5"
#     interval            = "120"
#     port                = 80
#     protocol            = "HTTP"
#     unhealthy_threshold = "2"
#     matcher             = "200-499"
#     timeout             = "5"
#   }

#   tags = local.tags
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_lb_listener" "ecs-example" { #tfsec:ignore:aws-elb-http-not-used LB has no public endpoints
#   load_balancer_arn = module.ecs_lb_access_logs_enabled.load_balancer.arn

#   default_action {
#     target_group_arn = aws_lb_target_group.ecs_target_group.arn
#     type             = "forward"
#   }
#   #checkov:skip=CKV_AWS_103:"LB has no public endpoints"
#   #checkov:skip=CKV_AWS_2:"LB has no public endpoints"
#   port = local.application_data.accounts[local.environment].server_port

#   depends_on = [aws_lb_target_group.ecs_target_group]
# }


# # ECS Security Group for ecs-cluster module
# resource "aws_security_group" "cluster_ec2" {
#   #checkov:skip=CKV_AWS_23
#   name        = "cluster_ec2"
#   description = "controls access to the cluster ec2 instance"
#   vpc_id      = data.aws_vpc.shared.id
#   dynamic "ingress" {
#     for_each = local.ec2_ingress_rules
#     content {
#       description     = lookup(ingress.value, "description", null)
#       from_port       = lookup(ingress.value, "from_port", null)
#       to_port         = lookup(ingress.value, "to_port", null)
#       protocol        = lookup(ingress.value, "protocol", null)
#       cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
#       security_groups = lookup(ingress.value, "security_groups", null)
#     }
#   }
#   dynamic "egress" {
#     for_each = local.ec2_egress_rules
#     content {
#       description     = lookup(egress.value, "description", null)
#       from_port       = lookup(egress.value, "from_port", null)
#       to_port         = lookup(egress.value, "to_port", null)
#       protocol        = lookup(egress.value, "protocol", null)
#       cidr_blocks     = lookup(egress.value, "cidr_blocks", null)
#       security_groups = lookup(egress.value, "security_groups", null)
#     }
#   }
#   tags = { Name = lower(format("sg-%s-%s-example", local.application_name, local.environment)) }
# }
