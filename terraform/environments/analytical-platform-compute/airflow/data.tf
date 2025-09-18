data "aws_vpc_endpoint" "mwaa_webserver" {
  service_name = aws_mwaa_environment.main.webserver_vpc_endpoint_service
}

data "dns_a_record_set" "mwaa_webserver_vpc_endpoint" {
  host = data.aws_vpc_endpoint.mwaa_webserver.dns_entry[0].dns_name
}

# APC VPC
data "aws_vpc" "apc_vpc" {
  tags = {
    "Name" = "${var.networking[0].application}-${local.environment}"
  }
}

data "aws_subnets" "apc_public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.apc_vpc.id]
  }
  tags = {
    Name = "${var.networking[0].application}-${local.environment}-public*"
  }
}

data "aws_subnet" "apc_private_subnet_a" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.apc_vpc.id]
  }
  tags = {
    Name = "${var.networking[0].application}-${local.environment}-private-${data.aws_region.current.region}a"
  }
}

data "aws_subnet" "apc_private_subnet_b" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.apc_vpc.id]
  }
  tags = {
    Name = "${var.networking[0].application}-${local.environment}-private-${data.aws_region.current.region}b"
  }
}

# ACM
data "aws_acm_certificate" "certificate" {
  domain   = local.environment_configuration.route53_zone
  statuses = ["ISSUED"]
}

# EKS
data "aws_eks_cluster" "apc_cluster" {
  name = local.eks_cluster_name
}

# KMS
data "aws_kms_key" "common_secrets_manager_kms" {
  key_id = "alias/secretsmanager/common"
}


data "aws_eks_cluster" "eks" {
  name = local.eks_cluster_name
}
