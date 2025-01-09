module "ecs" {
  source = "./modules/ecs"

  #Network details
  vpc_id         = data.aws_vpc.shared.id
  ecs_subnet_ids = local.private_subnet_list[*].id

  #ALB details 
  external_alb_security_group_id = module.external_alb.alb_security_group_id
  internal_alb_security_group_id = module.internal_alb.alb_security_group_id
  external_alb_arn               = module.external_alb.alb_arn
  internal_alb_arn               = module.internal_alb.alb_arn
  external_alb_name              = module.external_alb.alb_name
  internal_alb_name              = module.internal_alb.alb_name

  #ECS details
  cluster_name         = "yjaf-cluster"
  ec2_instance_type    = "m5.xlarge"
  ec2_min_size         = 1
  ec2_max_size         = 8
  ec2_desired_capacity = 5
  nameserver           = join(".", [split(".", data.aws_vpc.shared.cidr_block)[0], split(".", data.aws_vpc.shared.cidr_block)[1], "0", "2"]) #eg "10.23.0.2"

  #todo should be a ecs specific user instead of root user
  ecs_service_postgres_secret_arn = "arn:aws:secretsmanager:eu-west-2:012345678:secret:rds!cluster-9e616cc2-98fd-4b4a-af98-44b25c088ff8-KPsJBM"

  ecs_services = local.ecs_services

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags

  depends_on = [module.internal_alb, module.external_alb]
}
