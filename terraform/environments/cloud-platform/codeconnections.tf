###############################################################################
# AWS CodeConnections — GitHub access for EKS-managed ArgoCD
#
# The EKS ArgoCD Capability runs in AWS-managed infrastructure and cannot reach
# github.com directly. It clones repositories through the CodeConnections
# git-http proxy. One connection per account is sufficient — all clusters in
# the account share it.
#
# After Terraform creates this resource it will be in PENDING status.
# A one-time manual step is required to complete the GitHub OAuth handshake:
#   1. AWS Console → Developer Tools → Settings → Connections
#   2. Select the pending connection → "Update pending connection"
#   3. Authorize the AWS Connector GitHub App for the ministryofjustice org
#
# Once AVAILABLE, downstream components (cluster, cluster-core) look up the
# connection by name via data source — no cross-state references needed.
###############################################################################

resource "aws_codeconnections_connection" "github" {
  name          = "github-ministryofjustice"
  provider_type = "GitHub"

  tags = merge(local.tags, {
    Name = "github-ministryofjustice"
  })
}
