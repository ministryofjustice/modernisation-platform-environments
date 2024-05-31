/*
module "shield" {
  source = "../../modules/shield_advanced"
  providers = {
    aws.modernisation-platform = aws.modernisation-platform
  }
  application_name = local.application_name
  shielded_resources = {
    public_lb      = aws_lb.external.arn,
    certificate_lb = aws_lb.certificate_example_lb.arn
  }
  support_email = jsondecode(data.http.environments_file.response_body).tags.infrastructure-support
  tags          = local.tags
}
*/

data "external" "shield_protections" {
  program = [
    "bash", "-c",
    "aws shield list-protections --output json | jq -c '.Protections | map({(.Id): (. | tostring)}) | add'"
  ]
}

locals {
  shield_protections = tomap({
    for k, v in data.external.shield_protections.result :
    k => jsondecode(v)
  })
}