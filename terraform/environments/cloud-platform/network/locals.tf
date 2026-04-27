locals {
  mp_environments = [
    "cloud-platform-development",
    "cloud-platform-preproduction",
    "cloud-platform-nonlive",
    "cloud-platform-live",
  ]
  enabled_workspaces  = ["development_cluster"]
  cluster_environment = contains(local.mp_environments, terraform.workspace) ? local.environment : "development_cluster"
  cp_vpc_name         = terraform.workspace
  cp_vpc_cidr = {
    development_cluster = "10.0.0.0/16"
    development         = "10.1.0.0/16"
    preproduction       = "10.2.0.0/16"
    nonlive             = "10.195.0.0/16"
    live                = "10.41.0.0/16"
  }
  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_name_suffix       = local.cp_vpc_name
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60

  # VPC endpoint service names
  # Reference: https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html
  vpc_interface_endpoint_service_names = [
    "apigateway",       # API Gateway
    "athena",           # Athena
    "backup",           # AWS Backup
    "cloudtrail",       # CloudTrail
    "config",           # AWS Config
    "detective",        # AWS Detective
    "dms",              # AWS Database Migration Service
    "ec2",              # EC2
    "ecr.api",          # ECR (API)
    "ecr.dkr",          # ECR (Docker)
    "eks",              # EKS
    "eks-auth",         # EKS Auth
    "elasticache",      # ElastiCache
    "email",            # SES (API)
    "email-smtp",       # SES (SMTP)
    "events",           # CloudWatch Events
    "guardduty-data",   # GuardDuty
    "inspector2",       # Inspector
    "kinesis-firehose", # Kinesis Firehose
    "kms",              # KMS
    "lambda",           # Lambda
    "logs",             # CloudWatch Logs
    "rds",              # RDS
    "rds-data",         # RDS Data
    "secretsmanager",   # Secrets Manager
    "securityhub",      # Security Hub
    "sns",              # SNS
    "sqs",              # SQS
    "ssm",              # AWS Systems Manager
    "sts",              # STS
    "transcribe",       # AWS Transcribe
    "wafv2"             # WAF
  ]

  vpc_gateway_endpoint_service_names = [
    "s3",      # S3
    "dynamodb" # DynamoDB
  ]
}
