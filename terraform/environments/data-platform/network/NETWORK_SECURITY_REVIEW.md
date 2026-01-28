# Network Security Review - Data Platform Network Configuration

**Review Date**: 28 January 2026  
**Reviewer**: GitHub Copilot  
**Scope**: Comprehensive review of Terraform network configuration

---

## Executive Summary

This review evaluates the data platform network Terraform configuration against security best practices, focusing on:
- HCL code readability and structure
- YAML-driven configuration approach
- Route table and routing logic
- Deny-by-default security posture
- Logging and encryption coverage

### Overall Assessment

| Category | Rating | Notes |
|----------|--------|-------|
| **Security Posture** | ⭐⭐⭐⭐⭐ (5/5) | Excellent deny-by-default with full north-south traffic inspection |
| **Code Quality** | ⭐⭐⭐½ (3.5/5) | Good structure, but some complex expressions need simplification |
| **Routing Logic** | ⭐⭐⭐⭐⭐ (5/5) | Excellent architecture with proper traffic inspection and data tier isolation |

---

## ✅ Strengths & Good Practices

### 1. Excellent Logging Coverage

**VPC Flow Logs**
- ✅ Comprehensive flow log format including encryption status
- ✅ Configured for `ALL` traffic types
- ✅ Detailed fields captured for forensic analysis
- ✅ 365-day retention with KMS encryption

```terraform
resource "aws_flow_log" "vpc" {
  traffic_type    = "ALL"
  log_format      = "... encryption-status"
  # Full format string with 28+ fields
}
```

**Network Firewall Logging**
- ✅ Both FLOW and ALERT logs enabled
- ✅ CloudWatch Logs destination with KMS encryption
- ✅ Monitoring dashboard enabled
- ✅ 365-day retention

**Route53 Resolver Logging**
- ✅ Dual logging destinations (CloudWatch + S3)
- ✅ KMS encryption for CloudWatch logs
- ✅ Query logging for DNS security monitoring

**Encryption**
- ✅ All CloudWatch log groups use customer-managed KMS keys
- ✅ Appropriate key policies with service principals
- ✅ KMS key aliases follow consistent naming pattern
- ✅ Network Firewall resources encrypted at rest

### 2. Strong "Deny-by-Default" Architecture

**Network Firewall Configuration**
```terraform
firewall_policy {
  stateless_default_actions          = ["aws:forward_to_sfe"]
  stateless_fragment_default_actions = ["aws:drop"]
  
  stateful_engine_options {
    rule_order = "STRICT_ORDER"
  }
  
  stateful_default_actions = [
    "aws:drop_established",
    "aws:alert_established",
  ]
}
```

**Security Controls**
- ✅ STRICT_ORDER rule processing for predictable behaviour
- ✅ AWS managed threat intelligence rule groups (malware, botnets, C&C)
- ✅ Explicit allow-listing for FQDN (TLS SNI + HTTP host)
- ✅ Explicit allow-listing for IP-based protocols
- ✅ Static catch-all deny rules for HTTP/HTTPS/SSH
- ✅ Fragment dropping by default

**Route53 DNS Firewall**
- ✅ Fail-closed configuration (`firewall_fail_open = "DISABLED"`)
- ✅ Four AWS managed domain block lists enabled
- ✅ NXDOMAIN response for blocked domains

### 3. Well-Designed Routing Architecture

**Traffic Segmentation**
- ✅ Four subnet types with distinct purposes:
  - **Public**: Internet-facing resources with IGW access
  - **Firewall**: Network Firewall endpoints for traffic inspection
  - **Private**: Application workloads with NAT gateway egress
  - **Data**: Isolated data tier (no internet/TGW access)
- ✅ One route table per subnet for granular control
- ✅ Consistent naming: `{app}-{env}-{type}-{az}`
- ✅ **Data subnet isolation**: No explicit routes beyond implicit VPC local route, preventing internet and TGW egress whilst allowing intra-VPC connectivity

**Egress Traffic Flow (North-South)**
```
Private Subnets → Network Firewall → NAT Gateway → Internet
                                   ↓
                          Transit Gateway (filtered)
```

**Ingress Traffic Flow (North-South)**
```
Internet → IGW → Public Subnet (NLB) → Network Firewall → Private Subnet (EKS)
```

- ✅ All private subnet egress flows through Network Firewall
- ✅ **Public-to-private traffic inspection**: Specific routes force traffic through NFW
  - `public → private CIDR → Network Firewall endpoint` ensures inspection of ingress traffic
  - Critical for NLB → backend target traffic inspection
  - Prevents bypass via implicit local route
  - Firewall subnets dedicated to NFW endpoints only (no redundant routes needed)
- ✅ Symmetric routing with appliance mode on TGW attachment
- ✅ Security group referencing enabled for TGW
- ✅ Both ingress and egress traffic inspected by Network Firewall

**Transit Gateway Integration**
- ✅ Dedicated /28 subnets from separate CIDR block (100.64.255.0/24)
- ✅ Appliance mode support for symmetric routing
- ✅ Traffic from TGW routes through Network Firewall

### 4. Good YAML-Driven Configuration

**Network Configuration Structure**
```yaml
environment:
  {env}:
    vpc:
      cidr_block: 10.x.x.x/19
      additional_cidr_blocks:
        transit_gateway:
          cidr_block: 100.64.255.0/24
          subnets: { ... }
      subnets:
        data: { a: ..., b: ..., c: ... }
        firewall: { ... }
        public: { ... }
        private: { ... }
    transit_gateway:
      routes:
        - name: internal
          cidr: 10.0.0.0/8
          description: MoJ internal network
        - name: cloud-platform
          cidr: 172.20.0.0/16
          description: Cloud Platform
```

**Benefits**
- ✅ Clear CIDR allocation with inline IP range documentation
- ✅ Consistent structure across all environments
- ✅ Reserved ranges documented for future expansion
- ✅ Unallocated subnets clearly marked
- ✅ Transit gateway routes in YAML with descriptions for clarity

**Firewall Rules**
- ✅ Separate YAML files for FQDN and IP rules
- ✅ JSON schema validation references
- ✅ Structured rule format with all required fields
- ✅ Templating approach for Suricata rule generation

### 5. HCL Code Quality

**Phased Implementation Approach**
- ✅ Development environment as reference implementation
- ✅ Transit Gateway configuration ready for replication to other environments
- ✅ Well-structured for environment expansion

**Resource Management**
- ✅ Extensive use of `for_each` for dynamic resource creation
- ✅ DRY principle with computed subnet maps
- ✅ Module usage for common patterns (KMS, IAM, log groups)
- ✅ Consistent tagging strategy
- ✅ Transit gateway routes parsed from YAML with graceful fallback

**Documentation**
- ✅ Helpful debugging instructions in `locals.tf`
- ✅ Comments explaining complex CIDR calculations
- ✅ Inline documentation for configuration structure

**Best Practices**
- ✅ Explicit dependencies with `depends_on`
- ✅ Firewall protection flags enabled (delete, policy change, subnet change)
- ✅ IAM policies follow least privilege
- ✅ Terraform module version pinning with git refs

---

## ⚠️ Issues & Recommendations

### CRITICAL PRIORITY

**No critical issues identified.** All critical security controls are properly implemented.

---

### HIGH PRIORITY

#### 1. VPC Encryption Mode in Monitor Only

**Issue**: VPC encryption control is set to `monitor` mode instead of `full` enforcement.

**Current State**:
```terraform
resource "aws_vpc_encryption_control" "main" {
  vpc_id = aws_vpc.main.id
  mode   = "monitor"  # ⚠️ Only monitoring, not enforcing
}
```

**Impact**:
- VPC metrics show encryption usage but don't enforce it
- Unencrypted traffic is allowed between instances
- Good for testing, but production should enforce encryption

**Recommendation**:

Environment-specific encryption mode:
```terraform
resource "aws_vpc_encryption_control" "main" {
  vpc_id = aws_vpc.main.id
  mode   = local.environment == "development" ? "monitor" : "full"
  
  tags = {
    Name = "${local.application_name}-${local.environment}-encryption"
  }
}
```

Or full enforcement everywhere:
```terraform
resource "aws_vpc_encryption_control" "main" {
  vpc_id = aws_vpc.main.id
  mode   = "full"  # Enforce encryption in all environments
}
```

**Note**: `full` mode requires:
- Amazon Linux 2023, Ubuntu 22.04+, or RHEL 9+ instances
- Nitro-based instance types
- May affect existing workloads if not compatible

**Action Required**: ✋ **Consider upgrading to `full` mode for non-development environments**

---

### MEDIUM PRIORITY

#### 1. Complex Nested for_each Expressions

**Issue**: Subnet locals use deeply nested expressions that are difficult to read and maintain.

**Current Implementation**:
```terraform
# locals.tf
locals {
  subnets = merge([
    for subnet_type, azs in local.network_configuration.vpc.subnets : {
      for az, cidr in azs :
      "${subnet_type}-${az}" => {
        cidr_block = cidr
        type       = subnet_type
        az         = trimprefix(az, "az")
      }
    }
  ]...)
}
```

**Problems**:
- Triple-level nesting: `merge([for... {for...}]...)`
- Spread operator `...` usage not immediately obvious
- Difficult to debug intermediate values
- Hard to understand data transformation flow

**Recommendation**:

Break into intermediate steps:

```terraform
locals {
  # Step 1: Flatten subnet configuration into list
  subnet_list = flatten([
    for subnet_type, azs in local.network_configuration.vpc.subnets : [
      for az, cidr in azs : {
        key        = "${subnet_type}-${trimprefix(az, "az")}"
        cidr_block = cidr
        type       = subnet_type
        az         = trimprefix(az, "az")
      }
    ]
  ])

  # Step 2: Convert list to map with clear key structure
  subnets = { for s in local.subnet_list : s.key => {
    cidr_block = s.cidr_block
    type       = s.type
    az         = s.az
  }}
  
  # Step 3: Same approach for additional CIDR subnets
  additional_cidr_subnet_list = flatten([
    for block_name, block_config in try(local.network_configuration.vpc.additional_cidr_blocks, {}) : [
      for subnet_type, azs in block_config.subnets : [
        for az, cidr in azs : {
          key        = "${block_name}-${subnet_type}-${trimprefix(az, "az")}"
          cidr_block = cidr
          type       = subnet_type
          az         = trimprefix(az, "az")
          block_name = replace(block_name, "_", "-")
        }
      ]
    ]
  ])

  additional_cidr_subnets = { for s in local.additional_cidr_subnet_list : s.key => {
    cidr_block = s.cidr_block
    type       = s.type
    az         = s.az
    block_name = s.block_name
  }}
}
```

**Benefits**:
- Easier to debug: Can output `local.subnet_list` in terraform console
- Clear data flow: YAML → list → map
- Each step has single responsibility
- More maintainable

---

#### 2. Repetitive for_each Filter Patterns

**Issue**: The same for_each filter pattern repeats throughout the codebase.

**Examples**:
```terraform
# In nat-gateways.tf
resource "aws_nat_gateway" "main" {
  for_each = {
    for key, value in local.subnets : value.az => value
    if value.type == "public"
  }
}

# In routes.tf (multiple times)
resource "aws_route" "public_internet_gateway" {
  for_each = {
    for key, value in local.subnets : value.az => value
    if value.type == "public"
  }
}

resource "aws_route" "private_to_network_firewall" {
  for_each = {
    for key, value in local.subnets : value.az => value
    if value.type == "private"
  }
}
```

**Recommendation**:

Create reusable filtered locals:

```terraform
# In locals.tf
locals {
  # ... existing locals ...

  # Filtered subnet maps by type (indexed by AZ)
  public_subnets_by_az = {
    for key, value in local.subnets : value.az => value
    if value.type == "public"
  }
  
  private_subnets_by_az = {
    for key, value in local.subnets : value.az => value
    if value.type == "private"
  }
  
  firewall_subnets_by_az = {
    for key, value in local.subnets : value.az => value
    if value.type == "firewall"
  }
  
  data_subnets_by_az = {
    for key, value in local.subnets : value.az => value
    if value.type == "data"
  }

  # Filtered subnet maps by type (indexed by full key)
  public_subnets = {
    for key, value in local.subnets : key => value
    if value.type == "public"
  }
  
  private_subnets = {
    for key, value in local.subnets : key => value
    if value.type == "private"
  }
  
  firewall_subnets = {
    for key, value in local.subnets : key => value
    if value.type == "firewall"
  }
  
  data_subnets = {
    for key, value in local.subnets : key => value
    if value.type == "data"
  }
}
```

Then simplify resources:

```terraform
# nat-gateways.tf
resource "aws_nat_gateway" "main" {
  for_each = local.public_subnets_by_az
  # ...
}

# routes.tf
resource "aws_route" "public_internet_gateway" {
  for_each = local.public_subnets_by_az
  # ...
}

resource "aws_route" "private_to_network_firewall" {
  for_each = local.private_subnets_by_az
  # ...
}

# elastic-ips.tf
resource "aws_eip" "nat_gateway" {
  for_each = local.public_subnets_by_az
  # ...
}
```

**Benefits**:
- DRY principle: Filter logic in one place
- Easier to modify: Change filter criteria once
- Better performance: Computed once, reused many times
- Clearer intent: Variable names document purpose

---

#### 3. Hardcoded Subnet Mapping in Network Firewall

**Issue**: Network Firewall subnet mapping uses hardcoded subnet keys.

**Current State**:
```terraform
resource "aws_networkfirewall_firewall" "main" {
  # ...
  
  dynamic "subnet_mapping" {
    for_each = {
      "firewall-a" = aws_subnet.main["firewall-a"]
      "firewall-b" = aws_subnet.main["firewall-b"]
      "firewall-c" = aws_subnet.main["firewall-c"]
    }

    content {
      subnet_id = subnet_mapping.value.id
    }
  }
}
```

**Problems**:
- Breaks if AZ naming changes
- Doesn't adapt if firewall subnets aren't created
- Not DRY with other subnet filtering logic

**Recommendation**:

Use dynamic filtering:

```terraform
resource "aws_networkfirewall_firewall" "main" {
  name                = "${local.application_name}-${local.environment}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.strict.arn
  vpc_id              = aws_vpc.main.id

  # ... protection settings ...

  dynamic "subnet_mapping" {
    for_each = {
      for key, subnet in aws_subnet.main : key => subnet
      if startswith(key, "firewall-")
    }

    content {
      subnet_id = subnet_mapping.value.id
    }
  }
}
```

Or using the filtered local (if recommendation #8 is implemented):

```terraform
dynamic "subnet_mapping" {
  for_each = local.firewall_subnets

  content {
    subnet_id = aws_subnet.main[subnet_mapping.key].id
  }
}
```

**Benefits**:
- Adapts to any number of AZs
- Consistent with other resource patterns
- More maintainable

---

#### 4. Route53 Resolver Firewall Priority Calculation

**Issue**: Priority calculation uses `index()` function which is fragile if map order changes.

**Current State**:
```terraform
resource "aws_route53_resolver_firewall_rule" "aws_managed_domains" {
  for_each = local.route53_dns_firewall_aws_managed_domain_lists

  # ...
  priority = format("10%d", index(keys(local.route53_dns_firewall_aws_managed_domain_lists), each.key))
}
```

**Problems**:
- `index()` depends on key order in map
- Maps are unordered in Terraform < 0.12, ordered but fragile in >= 0.12
- If map keys are reordered, priorities change
- Can cause resource replacement
- Priority format "101", "102", "103" is implicit

**Recommendation**:

Use explicit priorities in the local:

```terraform
# route53-resolver-firewall.tf
locals {
  route53_dns_firewall_rules = {
    AWSManagedDomainsAggregateThreatList = {
      domain_list_id = "rslvr-fdl-4e96d4ce77f466b"
      priority       = 101
      description    = "Blocks domains on AWS aggregate threat list"
    }
    AWSManagedDomainsAmazonGuardDutyThreatList = {
      domain_list_id = "rslvr-fdl-876a86d96f294739"
      priority       = 102
      description    = "Blocks domains identified by GuardDuty"
    }
    AWSManagedDomainsBotnetCommandandControl = {
      domain_list_id = "rslvr-fdl-3268f74d91fe418f"
      priority       = 103
      description    = "Blocks known botnet C&C domains"
    }
    AWSManagedDomainsMalwareDomainList = {
      domain_list_id = "rslvr-fdl-4fc4edfc63854751"
      priority       = 104
      description    = "Blocks known malware domains"
    }
  }
}

resource "aws_route53_resolver_firewall_rule" "aws_managed_domains" {
  for_each = local.route53_dns_firewall_rules

  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.aws_managed_domains.id

  name                    = each.key
  action                  = "BLOCK"
  block_response          = "NXDOMAIN"
  firewall_domain_list_id = each.value.domain_list_id
  priority                = each.value.priority
}
```

**Benefits**:
- Explicit priorities, no implicit calculation
- Adding/removing rules doesn't affect others
- Self-documenting with descriptions
- Stable across terraform plan runs

---

### LOW PRIORITY

#### 1. Network Firewall Protection Flags

**Issue**: All protection flags are hardcoded to `true` for all environments.

**Current State**:
```terraform
resource "aws_networkfirewall_firewall" "main" {
  # ...
  
  delete_protection                 = true
  firewall_policy_change_protection = true
  subnet_change_protection          = true
}
```

**Consideration**: These protections prevent emergency changes in development/test environments.

**Recommendation**:

Environment-specific protection:

```terraform
resource "aws_networkfirewall_firewall" "main" {
  name                = "${local.application_name}-${local.environment}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.strict.arn
  vpc_id              = aws_vpc.main.id

  # Stricter protections in production, more flexibility in lower environments
  delete_protection                 = contains(["production", "preproduction"], local.environment)
  firewall_policy_change_protection = contains(["production", "preproduction"], local.environment)
  subnet_change_protection          = contains(["production", "preproduction"], local.environment)

  # ... rest of configuration ...
}
```

**Benefit**: Allows easier testing and iteration in development while maintaining production safety.

---

#### 2. Inconsistent Commenting Style

**Issue**: Mixed use of `#` and `/* */` comments throughout codebase.

**Examples**:
```terraform
# locals.tf - uses /* */ for multi-line
locals {
  /*  To debug these, you need to:
      1. cd terraform/environments/data-platform/network
      ...
  */
}

# routes.tf - uses # for single line
# Public subnet route table has:

# network.yml - uses # for YAML comments
# The two /18s are the unallocated ranges...
```

**Recommendation**:

Establish consistent convention:
- Use `#` for single-line comments
- Use `#` for multi-line comments (Terraform style guide)
- Reserve `/* */` only for temporarily commenting out code blocks

**Example**:
```terraform
# To debug these, you need to:
#   1. cd terraform/environments/data-platform/network
#   2. aws-sso login
#   3. aws-sso exec --profile data-platform-${STAGE:-"development"}:platform-engineer-admin
#   4. terraform init
#   5. terraform workspace select ${AWS_SSO_PROFILE%%:*}
#   6. terraform console
#   7. Type the local you want to debug, e.g. local.subnets
#
# If you make changes, you need to exit the console and re-run from step 6
```

---

#### 3. Missing Resource Descriptions

**Issue**: Some resources lack descriptions or comments explaining their purpose.

**Examples**:
- Route tables don't explain routing strategy
- Some security group rules lack context
- VPC endpoints don't document why specific services are included

**Recommendation**:

Add descriptive comments:

```terraform
# Route Tables
#
# Each subnet has its own route table for granular traffic control.
# This allows different routing behaviours per subnet type:
# - Public: Direct to IGW for internet access
# - Firewall: To NAT Gateway for filtered egress
# - Private: To Network Firewall for inspection
# - Data: No routes (air-gapped tier)
#
resource "aws_route_table" "main" {
  for_each = local.subnets

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.application_name}-${local.environment}-${each.value.type}-${each.value.az}"
  }
}
```

---

#### 4. VPC Endpoints Security Group Could Be More Restrictive

**Issue**: VPC endpoints security group allows all HTTPS from all private subnets.

**Current State**:
```terraform
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
```

**Consideration**: Could be more restrictive if only specific subnets need access.

**Recommendation** (optional):

If data subnets or other subnet types don't need VPC endpoint access:

```terraform
security_group_rules = {
  ingress_https_private = {
    description = "HTTPS from private subnets"
    cidr_blocks = [
      for key, subnet in local.subnets : subnet.cidr_block
      if subnet.type == "private"
    ]
  }
}
```

Or if data subnets need access too:

```terraform
security_group_rules = {
  ingress_https = {
    description = "HTTPS from private and data subnets"
    cidr_blocks = [
      for key, subnet in local.subnets : subnet.cidr_block
      if contains(["private", "data"], subnet.type)
    ]
  }
}
```

---

## 📊 Priority Summary

| Priority | Issue | Impact | Effort |
|----------|-------|--------|--------|
| 🟡 High | #1: VPC encryption in monitor mode | Medium | Low |
| 🟢 Medium | #1: Complex nested for_each | Low | Medium |
| 🟢 Medium | #2: Repetitive for_each filters | Low | Medium |
| 🟢 Medium | #3: Hardcoded firewall subnets | Low | Low |
| 🟢 Medium | #4: Route53 priority calculation | Low | Low |
| ⚪ Low | #1: Firewall protection flags | Low | Low |
| ⚪ Low | #2: Inconsistent commenting | Low | Low |
| ⚪ Low | #3: Missing descriptions | Low | Low |
| ⚪ Low | #4: VPC endpoint security group | Low | Low |

---

## 🔐 Security Checklist

### ✅ Implemented
- [x] VPC flow logs with encryption
- [x] Network Firewall with strict order processing
- [x] AWS managed threat intelligence feeds
- [x] Route53 Resolver query logging
- [x] Route53 DNS Firewall with malicious domain blocking
- [x] KMS encryption for all CloudWatch logs
- [x] Network Firewall encryption at rest
- [x] Explicit deny-by-default firewall rules
- [x] NAT gateway for private subnet egress
- [x] Transit gateway appliance mode for symmetric routing
- [x] Firewall protection flags (delete, policy, subnet)
- [x] VPC endpoint security groups
- [x] 365-day log retention
- [x] Dedicated firewall subnets per AZ
- [x] Security group referencing for TGW
- [x] YAML-driven transit gateway configuration
- [x] Data subnet routing (intentional isolation for data tier)
- [x] Public subnet routing (north-south inspection architecture)

### ⚠️ Review Required
- [ ] VPC encryption enforcement mode (consider `full` for production)

### 📋 Phased Rollout (Intentional)
- [x] Development environment fully configured (reference implementation)
- [ ] Transit gateway configuration rollout to test/preproduction/production (when ready)

### 🔄 Future Enhancements
- [ ] VPC encryption mode: monitor → full (production)
- [ ] Network ACLs for data subnet hard isolation
- [ ] VPC endpoint policies for least privilege
- [ ] GuardDuty VPC endpoint for DNS protection
- [ ] CloudWatch metric alarms for firewall drops
- [ ] Athena queries for flow log analysis

---

## 📝 Recommendations by File

### routes.tf
1. ✅ **COMPLETE**: Data subnet routing is correctly configured (intentional isolation)
2. ✅ **COMPLETE**: Public subnet routing correctly implements north-south traffic inspection
3. ✅ **COMPLETE**: Removed redundant public-to-firewall route
4. 🔄 Use filtered subnet locals instead of repeated for_each

### environment-configuration.tf
1. ✅ **COMPLETE**: Transit gateway routes migrated to YAML
2. 🔄 Add environment-specific firewall protection flags

### configuration/network.yml
1. ✅ **COMPLETE**: Transit gateway routes now defined in YAML with descriptions
2. 📋 **PHASED ROLLOUT**: Development environment complete, replicate to test/preprod/prod when ready

### locals.tf
1. 🔄 Simplify nested for_each with intermediate locals
2. 🔄 Add filtered subnet maps by type
3. 🔄 Document complex transformations

### network-firewalls.tf
1. 🔄 Use filtered subnets instead of hardcoded keys
2. 🔄 Add environment-specific protection flags

### route53-resolver-firewall.tf
1. 🔄 Use explicit priorities instead of index() calculation
2. 🔄 Add descriptions to rule configuration

### vpc.tf
1. ❗Consider environment-specific encryption mode
2. 🔄 Add tags to encryption control resource

### All Files
1. 🔄 Standardise commenting style (use # for comments)
2. 🔄 Add more descriptive comments for complex logic
3. 🔄 Document routing strategy and traffic flow

---

## 🎯 Next Steps

### Immediate Actions (This Sprint)
1. **Consider VPC encryption mode** - Evaluate upgrade to `full` mode for production environment

### Short Term (Next Sprint)
2. Implement filtered subnet locals for DRY code
3. Simplify complex for_each expressions

### Medium Term (Next Quarter)
4. Add comprehensive comments and documentation
5. Standardise commenting style
6. Implement network ACLs for data tier if needed

### Long Term (Phased Rollout)
7. Replicate network configuration to test/preproduction/production environments
8. Add CloudWatch alarms for network security monitoring
9. Implement VPC endpoint policies
10. Create runbook for firewall rule management
11. Consider GuardDuty VPC endpoint

---

## 📚 Additional Resources

### AWS Documentation
- [AWS Network Firewall - Strict Order Evaluation](https://docs.aws.amazon.com/network-firewall/latest/developerguide/suricata-rule-evaluation-order.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [Route53 Resolver DNS Firewall](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resolver-dns-firewall.html)
- [Transit Gateway Appliance Mode](https://docs.aws.amazon.com/vpc/latest/tgw/transit-gateway-appliance-scenario.html)
- [VPC Encryption](https://docs.aws.amazon.com/vpc/latest/userguide/encryption-control.html)

### Terraform Best Practices
- [Terraform AWS VPC Module](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [Terraform Complex Types](https://developer.hashicorp.com/terraform/language/expressions/type-constraints)
- [Terraform Style Guide](https://developer.hashicorp.com/terraform/language/style)

### MoJ Guidance
- [Modernisation Platform Terraform Style Guide](https://user-guide.modernisation-platform.service.justice.gov.uk/team/terraform-style-guide)
- [ministryofjustice/.github](https://github.com/ministryofjustice/.github)

---

**Review Completed**: 28 January 2026  
**Next Review Due**: Q2 2026 or after significant architecture changes
