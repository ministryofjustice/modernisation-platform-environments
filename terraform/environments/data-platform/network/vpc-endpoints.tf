module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.5.1"

  vpc_id = aws_vpc.main.id

  endpoints = merge({ for service in toset([
    "aps",
    "aps-workspaces",
    "athena",
    "autoscaling",
    "bedrock",
    "bedrock-runtime",
    "ec2",
    "ec2messages",
    "ecr.api",
    "ecr.dkr",
    "eks",
    "eks-auth",
    "elasticloadbalancing",
    "events",
    "glue",
    "guardduty-data",
    "kms",
    "lakeformation",
    "logs",
    "monitoring",
    "rds",
    "rds-data",
    "secretsmanager",
    "sns",
    "sqs",
    "ssm",
    "ssmmessages",
    "sts",
    ]) :
    replace(service, ".", "_") =>
    {
      service = service
      subnet_ids = [
        aws_subnet.main["private-a"].id,
        aws_subnet.main["private-b"].id,
        aws_subnet.main["private-c"].id
      ]
      private_dns_enabled = true
      tags                = { Name = "${local.application_name}-${local.environment}-${service}" }
    }
    },
    /*
      S3 utilises both Gateway and Interface endpoints. A Gateway endpoint is used for the main region, and an Interface endpoint is used for cross-region access.
    */
    {
      s3 = {
        service      = "s3"
        service_type = "Gateway"
        route_table_ids = [
          aws_route_table.main["private-a"].id,
          aws_route_table.main["private-b"].id,
          aws_route_table.main["private-c"].id
        ]
        tags = { Name = "${local.application_name}-${local.environment}-s3-gateway" }
      },
      s3-eu-west-1 = {
        service_name   = "com.amazonaws.eu-west-1.s3"
        service_region = "eu-west-1"
        service_type   = "Interface"
        subnet_ids = [
          aws_subnet.main["private-a"].id,
          aws_subnet.main["private-b"].id,
          aws_subnet.main["private-c"].id
        ]
        private_dns_enabled = true
        tags                = { Name = "${local.application_name}-${local.environment}-s3-eu-west-1-interface" }
      }
  })

  create_security_group      = true
  security_group_name_prefix = "${local.application_name}-${local.environment}-vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from subnets"
      cidr_blocks = [
        local.subnets["private-a"].cidr_block,
        local.subnets["private-b"].cidr_block,
        local.subnets["private-c"].cidr_block
      ]
    }
  }
}
