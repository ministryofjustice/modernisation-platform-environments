locals {

  # Allocations from the 10.0.0.0/16 VPC CIDR, one per AZ; prototypes hold 90% of allocated space.
  # 10.0.213.0 - 10.0.255.255 is left unallocated for future use.
  subnets = {
    public             = ["10.0.210.0/24", "10.0.211.0/24", "10.0.212.0/24"]
    private            = ["10.0.192.0/22", "10.0.196.0/22", "10.0.200.0/22"]
    data               = ["10.0.204.0/23", "10.0.206.0/23", "10.0.208.0/23"]
    public_prototypes  = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]
    private_prototypes = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
  }

  vpc_cidr     = local.application_data.accounts[local.environment].vpc_cidr
  network_name = "${local.application_name}-${local.environment}"

  # Tiers each tier may exchange traffic with; NACLs are stateless so this is applied in both directions.
  nacl_allowed_peers = {
    public             = ["public", "private"]
    private            = ["private", "public", "data"]
    data               = ["data", "private"]
    public_prototypes  = ["public_prototypes", "private_prototypes"]
    private_prototypes = ["private_prototypes", "public_prototypes"]
  }

  nacl_peer_rules = {
    for tier, peers in local.nacl_allowed_peers : tier => [
      for index, cidr in flatten([for peer in peers : local.subnets[peer]]) : {
        rule_number = 100 + (index * 10)
        rule_action = "allow"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_block  = cidr
      }
    ]
  }

  # Evaluated after the peer rules so the 0.0.0.0/0 rules below cannot reach other tiers.
  nacl_deny_vpc     = { rule_number = 900, rule_action = "deny", protocol = "-1", from_port = 0, to_port = 0, cidr_block = local.vpc_cidr }
  nacl_https        = { rule_number = 1000, rule_action = "allow", protocol = "tcp", from_port = 443, to_port = 443, cidr_block = "0.0.0.0/0" }
  nacl_ephemeral_in = { rule_number = 1000, rule_action = "allow", protocol = "tcp", from_port = 1024, to_port = 65535, cidr_block = "0.0.0.0/0" }
  nacl_all_out      = { rule_number = 1000, rule_action = "allow", protocol = "-1", from_port = 0, to_port = 0, cidr_block = "0.0.0.0/0" }

  nacl_inbound_rules = {
    public             = concat(local.nacl_peer_rules.public, [local.nacl_deny_vpc, local.nacl_https])
    private            = concat(local.nacl_peer_rules.private, [local.nacl_deny_vpc, local.nacl_ephemeral_in])
    data               = local.nacl_peer_rules.data
    public_prototypes  = concat(local.nacl_peer_rules.public_prototypes, [local.nacl_deny_vpc, local.nacl_https])
    private_prototypes = local.nacl_peer_rules.private_prototypes
  }

  nacl_outbound_rules = {
    public             = concat(local.nacl_peer_rules.public, [local.nacl_deny_vpc, local.nacl_all_out])
    private            = concat(local.nacl_peer_rules.private, [local.nacl_deny_vpc, local.nacl_https])
    data               = local.nacl_peer_rules.data
    public_prototypes  = concat(local.nacl_peer_rules.public_prototypes, [local.nacl_deny_vpc, local.nacl_all_out])
    private_prototypes = local.nacl_peer_rules.private_prototypes
  }

  prototype_tiers = ["public_prototypes", "private_prototypes"]

  prototype_subnets = merge([
    for tier in local.prototype_tiers : {
      for index, cidr in local.subnets[tier] : "${tier}-${local.availability_zones[index]}" => {
        tier              = tier
        cidr_block        = cidr
        availability_zone = local.availability_zones[index]
      }
    }
  ]...)

  # Interface endpoints created in the private subnets.
  interface_endpoints = [
    "logs",
    "sts",
    "ecr.api",
    "ecr.dkr",
    "states",
    "sync-states",
  ]

}

module "vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=a0307d4d1807de60b3868b96ef1b369808289157" # v6.0.1

  name = local.network_name
  azs  = local.availability_zones
  cidr = local.vpc_cidr

  public_subnets         = local.subnets.public
  private_subnets        = local.subnets.private
  database_subnets       = local.subnets.data
  database_subnet_suffix = "data"

  # Data gets its own route table so it does not inherit the private S3 endpoint route.
  create_database_subnet_route_table = true

  # Default NACL has no rules; every subnet is associated with a dedicated NACL.
  default_network_acl_ingress = []
  default_network_acl_egress  = []

  public_dedicated_network_acl   = true
  public_inbound_acl_rules       = local.nacl_inbound_rules.public
  public_outbound_acl_rules      = local.nacl_outbound_rules.public
  private_dedicated_network_acl  = true
  private_inbound_acl_rules      = local.nacl_inbound_rules.private
  private_outbound_acl_rules     = local.nacl_outbound_rules.private
  database_dedicated_network_acl = true
  database_inbound_acl_rules     = local.nacl_inbound_rules.data
  database_outbound_acl_rules    = local.nacl_outbound_rules.data

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 400

  tags = local.tags
}

################################################################################
# Prototype subnets (not supported as named tiers by the VPC module)
################################################################################

resource "aws_subnet" "prototypes" {
  for_each = local.prototype_subnets

  vpc_id            = module.vpc.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = merge(local.tags, { Name = "${local.network_name}-${replace(each.key, "_", "-")}" })
}

resource "aws_route_table" "prototypes" {
  for_each = toset(local.prototype_tiers)

  vpc_id = module.vpc.vpc_id

  tags = merge(local.tags, { Name = "${local.network_name}-${replace(each.key, "_", "-")}" })
}

resource "aws_route" "public_prototypes_internet" {
  route_table_id         = aws_route_table.prototypes["public_prototypes"].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.vpc.igw_id
}

resource "aws_route_table_association" "prototypes" {
  for_each = local.prototype_subnets

  subnet_id      = aws_subnet.prototypes[each.key].id
  route_table_id = aws_route_table.prototypes[each.value.tier].id
}

resource "aws_network_acl" "prototypes" {
  #checkov:skip=CKV_AWS_352:TODO restrict to required ports once inter-tier workload traffic is known
  for_each = toset(local.prototype_tiers)

  vpc_id     = module.vpc.vpc_id
  subnet_ids = [for key, subnet in local.prototype_subnets : aws_subnet.prototypes[key].id if subnet.tier == each.key]

  dynamic "ingress" {
    for_each = local.nacl_inbound_rules[each.key]
    content {
      rule_no    = ingress.value.rule_number
      action     = ingress.value.rule_action
      protocol   = ingress.value.protocol
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
      cidr_block = ingress.value.cidr_block
    }
  }

  dynamic "egress" {
    for_each = local.nacl_outbound_rules[each.key]
    content {
      rule_no    = egress.value.rule_number
      action     = egress.value.rule_action
      protocol   = egress.value.protocol
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
      cidr_block = egress.value.cidr_block
    }
  }

  tags = merge(local.tags, { Name = "${local.network_name}-${replace(each.key, "_", "-")}" })
}

################################################################################
# VPC Endpoints
################################################################################

module "vpc_endpoints" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source = "github.com/terraform-aws-modules/terraform-aws-vpc//modules/vpc-endpoints?ref=a0307d4d1807de60b3868b96ef1b369808289157" # v6.0.1

  security_group_ids = [aws_security_group.vpc_endpoints.id]
  subnet_ids         = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id

  endpoints = merge(
    {
      for service in local.interface_endpoints : replace(service, "/[.-]/", "_") => {
        service             = service
        service_type        = "Interface"
        private_dns_enabled = true
        tags = merge(
          local.tags,
          { Name = format("%s-%s-vpc-endpoint", local.application_name, replace(service, ".", "-")) }
        )
      }
    },
    {
      s3 = {
        service         = "s3"
        service_type    = "Gateway"
        route_table_ids = module.vpc.private_route_table_ids
        tags = merge(
          local.tags,
          { Name = format("%s-s3-vpc-endpoint", local.application_name) }
        )
      }
    }
  )
}

resource "aws_security_group" "vpc_endpoints" {
  #checkov:skip=CKV2_AWS_5:False positive; attached to endpoints via module.vpc_endpoints, which Checkov cannot trace
  description = "Security Group for controlling all VPC endpoint traffic"
  name        = format("%s-vpc-endpoint-sg", local.application_name)
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_https" {
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "Allow HTTPS from within the VPC"
  cidr_ipv4         = module.vpc.vpc_cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

output "vpc_id" {
  description = "ID of the VPC used by the justice-eng-ai environment."
  value       = module.vpc.vpc_id
}
