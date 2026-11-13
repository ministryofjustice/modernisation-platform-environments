# Serverless Customization Region Availability

Single source of truth for the AWS regions where SageMaker **serverless model
customization** (fine-tuning) is available. Other skill references point here
rather than repeating the list, so it only needs to be updated in one place.

## Supported regions

Serverless model customization is supported in:

| Region code | Location |
| --- | --- |
| `us-west-2` | Oregon |
| `us-east-1` | N. Virginia |
| `ap-northeast-1` | Tokyo |
| `eu-west-1` | Ireland |

> This list may expand over time. There is no runtime API to query serverless
> customization region availability, so this is maintained manually. See the
> [SageMaker serverless model customization documentation](https://docs.aws.amazon.com/sagemaker/latest/dg/customize-model.html)
> for the latest availability.

## Blocking message (use verbatim when a region is unsupported)

When the user's region is NOT in the list above and they want to fine-tune,
STOP and tell the user:

> "Serverless model customization is not available in your region
> (`<region>`). It is supported in: us-west-2, us-east-1,
> ap-northeast-1, and eu-west-1. I can help you deploy a base model instead, or
> you can switch to a supported region and try again."
