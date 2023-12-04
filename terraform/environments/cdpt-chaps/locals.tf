locals {
  app_data = jsondecode(file("./application_variables.json"))

  # ECS local variables for ecs.tf
  ec2_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description     = "Cluster EC2 loadbalancer ingress rule"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks     = []
      security_groups = [aws_security_group.load_balancer_security_group.id]
    },
  }
  ec2_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description     = "Cluster EC2 loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = [aws_security_group.load_balancer_security_group.id]
    }
  }

  task_definition = templatefile("task_definition.json", {
    app_name            = local.application_name
    ecr_url             = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/cdpt-chaps-ecr-repo"
    docker_image_tag    = local.application_data.accounts[local.environment].docker_image_tag
    region              = local.application_data.accounts[local.environment].region
  })

  user_data = base64encode(file("./user-data.txt"))
  # user_data = base64encode(templatefile("user_data.sh", {
  #   app_name = local.application_name
  # }))
}
