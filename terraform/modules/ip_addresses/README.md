# Overview

Put MoJ common IP addresses here to save duplication between environments.

Please see [MoJ Security Guidance](https://security-guidance.service.justice.gov.uk/ip-dns-diagram-handling/#ip-addresses-dns-information--architecture-documentation)

Please see internal repo <https://github.com/ministryofjustice/moj-ip-addresses>

## Suggested Naming Convention

- Variable ends in "cidr", a single cidr or a map of single cidrs.
- Variable ends in "cidrs", a list of cidrs, or a map of list of cidrs.
- Add a `_vpc` or `_vnet` to the name if AWS VPC or Azure VNET.
- Prefix with hosting location, e.g. `azure_` or `aws_` or `vodafone_wan_` or "arkc*" or "arkf*" etc.
- Postfix with `_aggregate` if the CIDR is a superset of multiple networks.
