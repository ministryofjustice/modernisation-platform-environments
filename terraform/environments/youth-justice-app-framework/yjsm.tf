
# YJSM EC2 Instance
locals {
  yjsm_buckets = jsonencode([
    "arn:aws:s3:::yjaf-${local.environment}-cms",
    "arn:aws:s3:::yjaf-${local.environment}-yjsm",
    "arn:aws:s3:::yjaf-${local.environment}-mis",
    "arn:aws:s3:::yjaf-${local.environment}-bedunlock",
    "arn:aws:s3:::yjaf-${local.environment}-yjsm-artefact",
    "arn:aws:s3:::yjaf-${local.environment}-bands",
    "arn:aws:s3:::yjaf-${local.environment}-cmm"
  ])
  yjsm_buckets_wildcarded = jsonencode([
    "arn:aws:s3:::yjaf-${local.environment}-cms/*",
    "arn:aws:s3:::yjaf-${local.environment}-yjsm/*",
    "arn:aws:s3:::yjaf-${local.environment}-mis/*",
    "arn:aws:s3:::yjaf-${local.environment}-bedunlock/*",
    "arn:aws:s3:::yjaf-${local.environment}-bands/*",
    "arn:aws:s3:::yjaf-${local.environment}-yjsm-artefact/*",
    "arn:aws:s3:::yjaf-${local.environment}-cmm/*"
  ])
}

module "yjsm" {
  source = "./modules/yjsm"

  #Network details
  vpc_id              = data.aws_vpc.shared.id
  subnet_id           = one(tolist([for s in local.private_subnet_list : s.id if s.availability_zone == "eu-west-2a"]))
  private_subnet_list = local.private_subnet_list
  # Assigning private IP based on environment
  private_ip = lookup(
    {
      development   = "10.26.144.61"
      test          = "10.26.152.172"
      preproduction = "10.27.144.83"
      production    = "10.27.152.21"
      # Add more environments when IP is known
    },
    local.environment,
    null # Default to null, allowing AWS to auto-assign an IP
  )

  ami = lookup(
    {
      development   = "ami-020f796d0dec4ed4c"
      test          = "ami-0b84f8ede56f98adf"
      preproduction = "ami-0d79a6afc87dfa388"
      production    = "ami-08e24cb718917177b"
      # Add more environments when AMIs are known
    },
    local.environment,
    "ami-01426769db5cd0a43" # Default AMI
  )

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags


  secret_kms_key_arn = module.kms.key_arn
  # Security Group IDs
  ecs_service_internal_sg_id    = module.ecs.ecs_service_internal_sg_id
  ecs_service_external_sg_id    = module.ecs.ecs_service_external_sg_id
  esb_service_sg_id             = module.esb.esb_security_group_id
  rds_cluster_security_group_id = module.aurora.rds_cluster_security_group_id
  alb_security_group_id         = module.internal_alb.alb_security_group_id
  management_server_sg_id       = module.ds.management_server_sg_id
  #Keep until prod images are done
  tableau_sg_id = module.tableau.tableau_sg_id

  region       = data.aws_region.current.name
  account_id   = data.aws_caller_identity.current.account_id
  cluster_name = "yjaf-cluster"

  yjsm_role_additional_policies_arns = [
    aws_iam_policy.yjsm-s3-access.arn,
    aws_iam_policy.yjsm-ses-access.arn
  ]

  yjsm_secrets_access_policy_secret_arns = jsonencode([
    module.aurora.app_rotated_postgres_secret_arn,
    aws_secretsmanager_secret.auto_admit_secret.arn
  ])
}


resource "aws_iam_policy" "yjsm-s3-access" {
  name        = "${local.project_name}-yjsm-s3-access"
  description = "Policy for yjsm task role to access yjaf buckets"
  policy = templatefile("${path.module}/iam_policies/s3_user_policy.json", {
    dal_buckets            = local.yjsm_buckets
    dal_buckets_wildcarded = local.yjsm_buckets_wildcarded
  })
}

resource "aws_iam_policy" "yjsm-ses-access" {
  name        = "${local.project_name}-yjsm-ses-access"
  description = "Policy for yjsm task role to access SES"
  policy      = file("${path.module}/iam_policies/ses_user_policy.json")
}
