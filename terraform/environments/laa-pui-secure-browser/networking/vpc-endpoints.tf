module "vpc_endpoints" {
  count = local.environment == "production" ? 1 : 0

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.5.1"

  vpc_id             = module.vpc[0].vpc_id
  subnet_ids         = module.vpc[0].intra_subnets
  security_group_ids = [module.vpc_endpoints_security_group[0].security_group_id]

  endpoints = {
    /* Interface Endpoints for AWS Services */
    sts = {
      service             = "sts"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-sts", module.vpc[0].name) }
      )
    },
    ec2 = {
      service             = "ec2"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ec2", module.vpc[0].name) }
      )
    },
    ec2messages = {
      service             = "ec2messages"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ec2messages", module.vpc[0].name) }
      )
    },
    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ssm", module.vpc[0].name) }
      )
    },
    ssmmessages = {
      service             = "ssmmessages"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ssmmessages", module.vpc[0].name) }
      )
    },
    logs = {
      service             = "logs"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-logs", module.vpc[0].name) }
      )
    },
    kms = {
      service             = "kms"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-kms", module.vpc[0].name) }
      )
    },
    secretsmanager = {
      service             = "secretsmanager"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-secretsmanager", module.vpc[0].name) }
      )
    },
    elasticloadbalancing = {
      service             = "elasticloadbalancing"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-elasticloadbalancing", module.vpc[0].name) }
      )
    },
    autoscaling = {
      service             = "autoscaling"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-autoscaling", module.vpc[0].name) }
      )
    },
    monitoring = {
      service             = "monitoring"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-monitoring", module.vpc[0].name) }
      )
    },
    sns = {
      service             = "sns"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-sns", module.vpc[0].name) }
      )
    },
    sqs = {
      service             = "sqs"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-sqs", module.vpc[0].name) }
      )
    },
    lambda = {
      service             = "lambda"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-lambda", module.vpc[0].name) }
      )
    },
    ecs = {
      service             = "ecs"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ecs", module.vpc[0].name) }
      )
    },
    ecs-agent = {
      service             = "ecs-agent"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ecs-agent", module.vpc[0].name) }
      )
    },
    ecs-telemetry = {
      service             = "ecs-telemetry"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ecs-telemetry", module.vpc[0].name) }
      )
    },
    ecr-api = {
      service             = "ecr.api"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ecr-api", module.vpc[0].name) }
      )
    },
    ecr-dkr = {
      service             = "ecr.dkr"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-ecr-dkr", module.vpc[0].name) }
      )
    },
    rds = {
      service             = "rds"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-rds", module.vpc[0].name) }
      )
    },
    rds-data = {
      service             = "rds-data"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-rds-data", module.vpc[0].name) }
      )
    },
    elasticache = {
      service             = "elasticache"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-elasticache", module.vpc[0].name) }
      )
    },
    athena = {
      service             = "athena"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-athena", module.vpc[0].name) }
      )
    },
    glue = {
      service             = "glue"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-glue", module.vpc[0].name) }
      )
    },
    xray = {
      service             = "xray"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-xray", module.vpc[0].name) }
      )
    },
    servicecatalog = {
      service             = "servicecatalog"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-servicecatalog", module.vpc[0].name) }
      )
    },
    cloudformation = {
      service             = "cloudformation"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-cloudformation", module.vpc[0].name) }
      )
    },
    events = {
      service             = "events"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-events", module.vpc[0].name) }
      )
    },
    states = {
      service             = "states"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-states", module.vpc[0].name) }
      )
    },
    elasticfilesystem = {
      service             = "elasticfilesystem"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-elasticfilesystem", module.vpc[0].name) }
      )
    },
    backup = {
      service             = "backup"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-backup", module.vpc[0].name) }
      )
    },
    guardduty-data = {
      service             = "guardduty-data"
      service_type        = "Interface"
      private_dns_enabled = true
      tags = merge(
        local.tags,
        { Name = format("%s-guardduty-data", module.vpc[0].name) }
      )
    },
    /* Gateway Endpoints */
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc[0].private_route_table_ids])
      tags = merge(
        local.tags,
        { Name = format("%s-s3", module.vpc[0].name) }
      )
    },
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc[0].private_route_table_ids])
      tags = merge(
        local.tags,
        { Name = format("%s-dynamodb", module.vpc[0].name) }
      )
    }
  }

  tags = local.tags
}
