# GuardDuty Eventbridge Rule

An Eventbridge rule that detects when a file fails a GuardDuty Malware scan and triggers a lambda.

## Usage
```hcl
module "data_factory_guardduty_eventbridge" {

    source = "github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/.."

    name = 'eventbridge_malware_event'

    bucket_names = ["avature-landing"]

    scan_result_statuses = ["THREATS_FOUND","FAILED", "ACCESS_DENIED"]

    target_lambda_name = module.data_factory_guardduty_lambda.name

    target_lambda_arn = module.data_factory_guardduty_lambda.arn

    tags = {
        Project     = "Avature"
        Owner       = "CorporateDataEngineering"
        }
}
```

<!--BEGIN_TF_DOCS-->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_event_rule.guardduty_quarantine](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.guardduty_quarantine_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_lambda_permission.allow_eventbridge_quarantine](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_names"></a> [bucket\_names](#input\_bucket\_names) | Names of the S3 buckets to apply rule to. | `list(string)` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the EventBridge rule. | `string` | `"eventbridge-guardduty-quarantine"` | no |
| <a name="input_scan_result_statuses"></a> [scan\_result\_statuses](#input\_scan\_result\_statuses) | List of scan result statuses to match in the EventBridge rule. | `list(string)` | <pre>[<br/>  "THREATS_FOUND",<br/>  "FAILED",<br/>  "ACCESS_DENIED"<br/>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to created resources. | `map(string)` | `{}` | no |
| <a name="input_target_lambda_arn"></a> [target\_lambda\_arn](#input\_target\_lambda\_arn) | ARN of the target Lambda function. | `string` | n/a | yes |
| <a name="input_target_lambda_name"></a> [target\_lambda\_name](#input\_target\_lambda\_name) | Name of the target Lambda function. | `string` | `"quarantine-lambda"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_rule_arn"></a> [rule\_arn](#output\_rule\_arn) | ARN of the EventBridge rule. |
<!--END_TF_DOCS-->