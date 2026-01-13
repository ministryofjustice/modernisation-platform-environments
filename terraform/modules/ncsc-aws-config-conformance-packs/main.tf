locals {
  aws_config_conformance_packs = {
    ncsc-cloud-security-principles = {
      source = "https://raw.githubusercontent.com/awslabs/aws-config-rules/refs/heads/master/aws-config-conformance-packs/Operational-Best-Practices-for-NCSC-CloudSec-Principles.yaml"
    }
    ncsc-cyber-assessment-framework = {
      source = "https://raw.githubusercontent.com/awslabs/aws-config-rules/refs/heads/master/aws-config-conformance-packs/Operational-Best-Practices-for-NCSC-CAF.yaml"
    }
  }
}

data "http" "aws_config_conformance_packs" {
  for_each = local.aws_config_conformance_packs
  url      = each.value.source
}

resource "aws_config_conformance_pack" "this" {
  for_each = local.aws_config_conformance_packs

  name          = each.key
  template_body = data.http.aws_config_conformance_packs[each.key].body
}
