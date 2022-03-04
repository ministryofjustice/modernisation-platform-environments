#------------------------------------------------------------------------------
# Networking data sources
#------------------------------------------------------------------------------

# get shared subnet-set vpc object
data "aws_vpc" "shared_vpc" {
  tags = {
    Name = "${var.business_unit}-${var.environment}"
  }
}

data "aws_subnet_ids" "local_account" {
  vpc_id = data.aws_vpc.shared_vpc.id
}

data "aws_subnet" "local_account" {
  for_each = data.aws_subnet_ids.local_account.ids
  id       = each.value
}

# get shared subnet-set private (az (a) subnet)
data "aws_subnet" "private_az_a" {
  tags = {
    Name = "${var.business_unit}-${var.environment}-${var.subnet_set}-private-${var.region}a"
  }
}

# get shared subnet-set data (az (a) subnet)
data "aws_subnet" "data_az_a" {
  tags = {
    Name = "${var.business_unit}-${var.environment}-${var.subnet_set}-data-${var.region}a"
  }
}

#------------------------------------------------------------------------------
# Route 53 zone
#------------------------------------------------------------------------------
data "aws_route53_zone" "internal" {
  provider = aws.core-vpc

  name         = "${var.business_unit}-${var.environment}.modernisation-platform.internal."
  private_zone = true
}

data "aws_route53_zone" "external" {
  provider = aws.core-vpc

  name         = "${var.business_unit}-${var.environment}.modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

#------------------------------------------------------------------------------
# This account id
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}