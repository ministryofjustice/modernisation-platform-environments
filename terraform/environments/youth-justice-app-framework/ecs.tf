locals {
  list_of_target_group_arns = merge(module.external_alb.target_group_arns, module.internal_alb.target_group_arns)
}

#tfsec:ignore:AVD-AWS-0130
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
  cluster_name                = "yjaf-cluster"
  ec2_instance_type           = "m5.xlarge"
  ec2_min_size                = 16
  ec2_max_size                = 16
  ec2_desired_capacity        = 16
  disable_overnight_scheduler = local.application_data.accounts[local.environment].disable_overnight_ecs_scheduler                                  #todo shared from old yjaf, replace with output of ami builder
  nameserver                  = join(".", [split(".", data.aws_vpc.shared.cidr_block)[0], split(".", data.aws_vpc.shared.cidr_block)[1], "0", "2"]) #eg "10.23.0.2"

  spot_overrides = [
    {
      instance_type     = "t3.xlarge"
      weighted_capacity = "3"
    },
    {
      instance_type     = "m5.large"
      weighted_capacity = "2"
    },
    {
      instance_type     = "t3.large"
      weighted_capacity = "1"
    }
  ]

  #todo should be a ecs specific user instead of root user
  ecs_service_postgres_secret_arn = module.aurora.app_rotated_postgres_secret_arn
  ecs_allowed_secret_arns         = [module.aurora.app_rotated_postgres_secret_arn, aws_secretsmanager_secret.LDAP_administration_secret.arn]
  ecs_services                    = local.ecs_services

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags

  #RDS and Redshift Details
  rds_postgresql_sg_id = module.aurora.rds_cluster_security_group_id
  redshift_sg_id       = module.redshift.security_group_id

  secret_kms_key_arn = module.kms.key_arn
  ecs_secrets_access_policy_secret_arns = jsonencode([
    module.aurora.app_rotated_postgres_secret_arn,
    aws_secretsmanager_secret.LDAP_administration_secret.arn,
    aws_secretsmanager_secret.LDAP_DC_secret.arn,
    aws_secretsmanager_secret.Auth_Email_Account.arn,
    aws_secretsmanager_secret.auto_admit_secret.arn,
    aws_secretsmanager_secret.Unit_test.arn,
    aws_secretsmanager_secret.s3_user_secret.arn,
    aws_secretsmanager_secret.yjaf_credentials.arn
  ])
  ecs_role_additional_policies_arns = [
    aws_iam_policy.s3-access.arn
  ]

  list_of_target_group_arns = local.list_of_target_group_arns

  depends_on = [module.internal_alb, module.external_alb, module.aurora, module.redshift]
}


resource "aws_iam_policy" "s3-access" {
  name        = "${local.project_name}-ecs-s3-access"
  description = "Policy for ecs task role to access yjaf buckets"
  policy = templatefile("${path.module}/iam_policies/s3_user_policy.json", {
    dal_buckets = jsonencode([
      "arn:aws:s3:::yjaf-${local.environment}-cms/*",
      "arn:aws:s3:::yjaf-${local.environment}-yjsm/*",
      "arn:aws:s3:::yjaf-${local.environment}-mis/*",
      "arn:aws:s3:::yjaf-${local.environment}-bedunlock/*",
      "arn:aws:s3:::yjaf-${local.environment}-bands/*",
      "arn:aws:s3:::yjaf-${local.environment}-incident/*",
      "arn:aws:s3:::yjaf-${local.environment}-cmm/*"
    ])
  })
}

