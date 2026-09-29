# File dispatch configuration

This module keeps file dispatch configuration in one place. The parent file-transfer component uses it to create dispatch secrets, while each delivery pattern uses it to create only the resources needed for that pattern.

These components have separate Terraform state. Keeping the configuration in a local module means each component can read the same source directly. We do not have to copy the configuration between components or make one deployment depend on another component's state.

Sensitive notification values and credentials must not be committed here. Terraform creates each dispatch secret with an initial value and ignores subsequent secret-value changes so that operators can populate sensitive values directly in AWS Secrets Manager.

## Why there are two outputs

`prefixes` preserves the configuration as it is written: identities contain source prefixes, and each prefix contains its dispatch settings. This shape is easier to read and edit, and the parent component uses it when creating secrets.

`entries` presents the same non-sensitive action settings in a form suited to Terraform resources. Each entry is keyed by a short identifier derived from its identity and source prefix. Delivery patterns can filter this map by action and use it directly with `for_each`.

The identifier keeps resource addresses stable when destination settings change and avoids putting identity names or path characters into AWS resource names. Changing the identity or source prefix creates a new logical entry, which is intentional because it changes which files the entry applies to.

Only information needed by delivery-pattern resources is included in each entry: the identity, source prefix, and action. Secret names and other derived values are built where they are used instead of being repeated in this module's interface.

## Action configuration

Each transfer identity contains one or more source prefixes. Prefixes must start and end with `/`; `/` configures the identity root.

`push-to-s3` delivers a clean object to a customer-managed bucket:

```hcl
action = {
  name = "push-to-s3"
  push_to_s3 = {
    bucket_id          = "customer-bucket"
    bucket_region      = "eu-west-2"
    destination_prefix = "bag-end/"
    kms_key_arn        = "arn:aws:kms:eu-west-2:123456789012:key/example"
  }
}
```

`push-to-s3-with-hosted-pickup` delivers a clean object to an Integration Hub managed bucket. The customer pickup role is intentionally not part of the initial implementation until its trusted principal contract is agreed.

```hcl
action = {
  name = "push-to-s3-with-hosted-pickup"
  push_to_s3_with_hosted_pickup = {
    destination_prefix = "pickup/"
    retention_days     = 30
  }
}
```

The default region for both patterns is `eu-west-2`.