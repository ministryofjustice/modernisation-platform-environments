
module "aurora" {
  source       = "./modules/aurora"
  project_name = local.project_name
  vpc_id       = data.aws_vpc.shared.id
  tags         = local.tags

  database_subnets           = local.data_subnet_list[*].id
  alb_route53_record_zone_id = data.aws_route53_zone.yjaf-inner.id


  name                       = "yjafrds01-cluster"
  azs                        = ["eu-west-2a", "eu-west-2b"]
  db_cluster_instance_class  = "db.t4g.medium"
  database_subnet_group_name = "yjaf-db-subnet-group"
  alb_route53_record_name    = "db-yjafrds01"

  #one time restore from a shared snapshot on preprod
  snapshot_identifier = "arn:aws:rds:eu-west-2:053556912568:cluster-snapshot:sharedwithdevencrypt"

  user_passwords_to_reset = ["postgres_rotated"]

  engine          = "aurora-postgresql"
  engine_version  = "16.2"
  master_username = "root"

  create_sheduler              = true
  stop_aurora_cluster_schedule = "cron(00 00 ? * MON-FRI *)"
  performance_insights_enabled = true

  #pass in provider for creating records on central route53
  providers = {
    aws                       = aws
    aws.core-network-services = aws.core-network-services
  }
  kms_key_arn = module.kms.key_arn
  kms_key_id  = module.kms.key_id

  # todo - some of these rules are commented out as the resource doesn't exist yet. 
  # It would make more sense the add the rules in their respective modules rather than here
  rds_security_group_ingress = [
    {
      from_port   = "5432"
      to_port     = "5432"
      protocol    = "tcp"
      description = "Dummy rule"
      cidr_blocks = [data.aws_vpc.shared.cidr_block] #todo change to real sg rules
    }
    /*
    windows_mgmt_servers = {
      from_port   = "5432"
      to_port     = "5432"
      protocol    = "tcp"
      description = "Access from mgmt servers on the local account"
      source_security_group_id = "sg-blablabla"
    }
    quicksight = {
      source_security_group_id = "sg-blablabla"
      from_port   = "5432"
      to_port     = "5432"
      protocol    = "tcp"
      description = "Quicksight access to postgres"
    }
    redshift = {
      source_security_group_id = "sg-blablabla"
      from_port   = "5432"
      to_port     = "5432"
      protocol    = "tcp"
      description = "Redshift access to postgres"
    }
    yjsm = {
      source_security_group_id = "sg-blablabla" 
      from_port   = "5432"
      to_port     = "5432"
      protocol    = "tcp"
      description = "YJSM access to postgres"
    }
    tableau = {
      source_security_group_id = "sg-blablabla"
      from_port   = "5432"
      to_port     = "5432"
      protocol    = "tcp"
      description = "Tableau access to postgres"
    }
    ecs_to_postgres = {
      source_security_group_id = "sg-blablabla" 
      from_port   = "5432"
      to_port     = "5432"
      protocol    = "tcp"
      description = "ECS to Postgres access"
    }
    mgmt_access = {
      source_security_group_id = "sg-blablabla" 
      from_port   = "5432"
      to_port     = "5432"
      protocol    = "tcp"
      description = "Whitelisted mgmt account access"
    }
  */
  ]
}
