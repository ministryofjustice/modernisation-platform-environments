# Shield Advanced module

## Description

This module allows users to implement the Modernisation Platform user guidance for implementing AWS Shield Advanced
without needing to resort to ClickOps processes.

Because the `aws_wafv2_web_acl` is pre-created by AWS Firewall Manager via the MOJ Root Account code, it needs to be
imported as part of the module setup. This can be done via the command line, or with an import block.

```hcl
import {
  id = "c6f3ba81-c457-40f6-bd1f-30e777f60c27/FMManagedWebACLV2-shield_advanced_auto_remediate-1652297838425/REGIONAL"
  to = module.shield.aws_wafv2_web_acl.main
}
```

Using a data source it is possible to create an import block that is dynamic, allowing you to import for all environments in one run.

```hcl
data "external" "shield_waf" {
  program = [
    "bash", "-c",
    "aws wafv2 list-web-acls --scope REGIONAL --output json | jq -c '{arn: .WebACLs[] | select(.Name | contains(\"FMManagedWebACL\")) | .ARN, name: .WebACLs[] | select(.Name | contains(\"FMManagedWebACL\")) | .Name}'"
  ]
}

locals {
  split_arn = split("regional/webacl/", data.external.shield_waf.result["arn"])[1]
  name = data.external.shield_waf.result["name"]
  id = split("/", local.split_arn)[1]
  scope = "REGIONAL"
}

import {
  id = "${local.id}/${local.name}/${local.scope}"
  to = module.shield.aws_wafv2_web_acl.main
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_aws.modernisation-platform"></a> [aws.modernisation-platform](#provider\_aws.modernisation-platform) | ~> 5.0 |
| <a name="provider_external"></a> [external](#provider\_external) | ~> 2.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_pagerduty_core_alerts"></a> [pagerduty\_core\_alerts](#module\_pagerduty\_core\_alerts) | github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration | 0179859e6fafc567843cd55c0b05d325d5012dc4 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.waf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_shield_application_layer_automatic_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/shield_application_layer_automatic_response) | resource |
| [aws_shield_drt_access_role_arn_association.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/shield_drt_access_role_arn_association) | resource |
| [aws_sns_topic.module_ddos_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_wafv2_web_acl.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_wafv2_web_acl_logging_configuration.waf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration) | resource |
| [aws_iam_role.srt_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_kms_key.sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_secretsmanager_secret.pagerduty_integration_keys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.pagerduty_integration_keys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [external_external.shield_protections](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.shield_waf](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name of application being protected. | `string` | n/a | yes |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Enable logging for the WAF ACL. | `bool` | `false` | no |
| <a name="input_excluded_protections"></a> [excluded\_protections](#input\_excluded\_protections) | A list of strings to not associate with the AWS Shield WAF ACL. | `set(string)` | `[]` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | Number of days to retain logs in CloudWatch Logs. | `number` | `60` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Map of resource ARNs and optional automatic response actions. | `map(any)` | n/a | yes |
| <a name="input_waf_acl_rules"></a> [waf\_acl\_rules](#input\_waf\_acl\_rules) | A map of values to be used in a dynamic WAF ACL rule block. | `map(any)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
