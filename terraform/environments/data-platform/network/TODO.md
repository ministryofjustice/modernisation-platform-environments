# Network TODO

- [x] KMS for NFW
- [ ] Logging with KMS for NFW, R53 and VPC flow logs
- [ ] Look at switching data.aws_vpc_endpoint.network_firewall with the sync state output from the firewall resource
- [ ] Review `public_to_*` routes as per comment
- [ ] Replace module refernces with pinned git tags
- [ ] Review logging KMS keys conditions
- [ ] Flow monitoring
- [ ] Fix permissions for R53 resolver logging association
- [ ] Review routes public_to_firewall_subnets public_to_private_subnets