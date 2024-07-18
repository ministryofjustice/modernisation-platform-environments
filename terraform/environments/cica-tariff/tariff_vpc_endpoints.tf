#Create endpoints to allow SSM from within private subnets

#ssm
resource "aws_vpc_endpoint" "ssm" {
    vpc_id = data.aws_vpc.shared.id
    service_name = "com.amazonaws.eu-west-2.ssm"
    vpc_endpoint_type = "Interface"
    subnet_ids = data.aws_subnets.shared-private[*].id
    tags = merge(tomap({
    "Name"     = lower(format("ssm-%s-endpoint", local.application_name)),
    "hostname" = "${local.application_name}-app",
  }), local.tags)

}

resource "aws_vpc_endpoint" "ec2messages" {
    vpc_id = data.aws_vpc.shared.id
    service_name = "com.amazonaws.eu-west-2.ec2messages"
    vpc_endpoint_type = "Interface"
    subnet_ids = data.aws_subnets.shared-private[*].id
    tags = merge(tomap({
    "Name"     = lower(format("ec2-messages-%s-endpoint", local.application_name)),
    "hostname" = "${local.application_name}-app",
  }), local.tags)

}



resource "aws_vpc_endpoint" "ec2" {
    vpc_id = data.aws_vpc.shared.id
    service_name = "com.amazonaws.eu-west-2.ec2"
    vpc_endpoint_type = "Interface"
    subnet_ids = data.aws_subnets.shared-private[*].id
    tags = merge(tomap({
    "Name"     = lower(format("ec2-%s-endpoint", local.application_name)),
    "hostname" = "${local.application_name}-app",
  }), local.tags)

}
resource "aws_vpc_endpoint" "ssm_messages" {
    vpc_id = data.aws_vpc.shared.id
    service_name = "com.amazonaws.eu-west-2.ssmmessages"
    vpc_endpoint_type = "Interface"
    subnet_ids = data.aws_subnets.shared-private[*].id
    tags = merge(tomap({
    "Name"     = lower(format("ssm-messages-%s-endpoint", local.application_name)),
    "hostname" = "${local.application_name}-app",
  }), local.tags)

}

resource "aws_vpc_endpoint" "kms" {
    vpc_id = data.aws_vpc.shared.id
    service_name = "com.amazonaws.eu-west-2.kms"
    vpc_endpoint_type = "Interface"
    subnet_ids = data.aws_subnets.shared-private[*].id
    tags = merge(tomap({
    "Name"     = lower(format("kms-%s-endpoint", local.application_name)),
    "hostname" = "${local.application_name}-app",
  }), local.tags)

}

resource "aws_vpc_endpoint" "logs" {
    vpc_id = data.aws_vpc.shared.id
    service_name = "com.amazonaws.eu-west-2.logs"
    vpc_endpoint_type = "Interface"
    subnet_ids = data.aws_subnets.shared-private[*].id
    tags = merge(tomap({
    "Name"     = lower(format("logs-%s-endpoint", local.application_name)),
    "hostname" = "${local.application_name}-app",
  }), local.tags)
}
