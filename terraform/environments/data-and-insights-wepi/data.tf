# Current account data
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# VPC and subnet data
data "aws_vpc" "wepi_vpc" {
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}"
  }
}

data "aws_subnets" "wepi_vpc_subnets_data_all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.wepi_vpc.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data*"
  }
}

data "aws_subnets" "wepi_vpc_subnets_private_all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.wepi_vpc.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private*"
  }
}

data "aws_subnets" "wepi_vpc_subnets_public_all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.wepi_vpc.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public*"
  }
}

data "aws_subnet" "wepi_vpc_subnets_data_a" {
  vpc_id = data.aws_vpc.wepi_vpc.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "wepi_vpc_subnets_data_b" {
  vpc_id = data.aws_vpc.wepi_vpc.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "wepi_vpc_subnets_data_c" {
  vpc_id = data.aws_vpc.wepi_vpc.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data-${data.aws_region.current.name}c"
  }
}

data "aws_subnet" "wepi_vpc_subnets_private_a" {
  vpc_id = data.aws_vpc.wepi_vpc.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "wepi_vpc_subnets_private_b" {
  vpc_id = data.aws_vpc.wepi_vpc.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "wepi_vpc_subnets_private_c" {
  vpc_id = data.aws_vpc.wepi_vpc.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${data.aws_region.current.name}c"
  }
}

data "aws_subnet" "wepi_vpc_subnets_public_a" {
  vpc_id = data.aws_vpc.wepi_vpc.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public-${data.aws_region.current.name}a"
  }
}

data "aws_subnet" "wepi_vpc_subnets_public_b" {
  vpc_id = data.aws_vpc.wepi_vpc.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public-${data.aws_region.current.name}b"
  }
}

data "aws_subnet" "wepi_vpc_subnets_public_c" {
  vpc_id = data.aws_vpc.wepi_vpc.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public-${data.aws_region.current.name}c"
  }
}

data "aws_vpc_endpoint" "s3" {
  provider     = aws.core-vpc
  vpc_id       = data.aws_vpc.wepi_vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-com.amazonaws.${data.aws_region.current.name}.s3"
  }

}

data "aws_redshift_service_account" "this" {}

data "aws_iam_policy_document" "s3_redshift" {
  statement {
    sid       = "RedshiftAcl"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.wepi_redshift_logging_bucket.id]

    principals {
      type        = "AWS"
      identifiers = [data.aws_redshift_service_account.this.arn]
    }
  }

  statement {
    sid       = "RedshiftWrite"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.wepi_redshift_logging_bucket.id}/*"]
    condition {
      test     = "StringEquals"
      values   = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }

    principals {
      type        = "AWS"
      identifiers = [data.aws_redshift_service_account.this.arn]
    }
  }
}