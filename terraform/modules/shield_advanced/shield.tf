data "aws_iam_role" "srt_access" {
  name = "AWSSRTSupport"
}

data "external" "shield_protections" {
  program = [
    "bash", "-c",
    "aws shield list-protections --output json | jq -c '.Protections | map({(.Id): (. | tostring)}) | add'"
  ]
}

data "external" "shield_waf" {
  program = [
    "bash", "-c",
    "aws wafv2 list-web-acls --scope REGIONAL --output json | jq -c '{arn: .WebACLs[] | select(.Name | contains(\"FMManagedWebACL\")) | .ARN}'"
  ]
}

locals {
  shield_protections = tomap({
    for k, v in data.external.shield_protections.result :
    k => jsondecode(v)
  })
}

resource "aws_shield_drt_access_role_arn_association" "main" {
  role_arn = data.aws_iam_role.srt_access.arn
}

resource "aws_wafv2_web_acl_association" "this" {
  for_each     = local.shield_protections
  resource_arn = each.value["ProtectionArn"]
  web_acl_arn  = data.external.shield_waf.result["arn"]
}
