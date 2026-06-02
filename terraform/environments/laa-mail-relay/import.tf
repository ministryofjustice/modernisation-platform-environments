# import.tf — no import blocks required.
#
# All resources are either:
#   - already in state (test/preprod/prod secrets and Route53)
#   - do not exist in AWS dev (dev secrets/Route53 will be created fresh by Terraform)
#   - decommissioned (IAM user/key — count=0 in ses.tf)
