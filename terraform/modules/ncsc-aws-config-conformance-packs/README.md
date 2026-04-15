# NCSC AWS Config Conformance Packs

This module deploys NCSC's AWS Config Conformance Packs for:

- [Operational Best Practices for NCSC Cloud Security Principles](https://docs.aws.amazon.com/config/latest/developerguide/operational-best-practices-for-ncsc.html)
- [Operational Best Practices for NCSC Cyber Assesment Framework](https://docs.aws.amazon.com/config/latest/developerguide/operational-best-practices-for-ncsc_cafv3.html)

## Example Usage

```hcl
module "ncsc_aws_config_conformance_packs" {
  source "../../modules/ncsc-aws-config-conformance-packs"
}
```
