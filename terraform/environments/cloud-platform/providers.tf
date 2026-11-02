# OpenSearch provider — manages security roles and role mappings inside the
# shared log domain for per-BU index isolation (cloud-platform#8592). See ADR-017.
#
# Same plan-time rule as Grafana: the URL can't come from a resource created in
# this apply. It comes from a data source that is only read once the domain
# exists and roles are switched on (local.opensearch_roles_enabled). Elsewhere a
# placeholder URL is used: configuring the provider makes no network call, and
# every opensearch_* resource is gated off, so it is never contacted.
#
# Auth is SigV4. This provider does not use the aws provider's assume_role, so
# it switches role itself, matching platform_providers.tf:
#   - apply job (session "githubactionsrolesession"): assumes MemberInfrastructureAccess.
#     github-actions-apply can't write to the domain (ReadOnlyAccess); this role
#     can, and is already mapped to all_access + security_manager in OpenSearch.
#   - plan job (github-actions-plan) and local runs: use their own credentials.
#     github-actions-plan can only read (ReadOnlyAccess) and needs a one-off
#     read mapping inside OpenSearch before roles are switched on (see #8592).
provider "opensearch" {
  url                 = local.opensearch_roles_enabled ? "https://${data.aws_opensearch_domain.logs[0].endpoint}" : "https://opensearch-not-enabled.invalid"
  aws_region          = data.aws_region.current.region
  aws_assume_role_arn = can(regex("githubactionsrolesession", data.aws_caller_identity.original_session.arn)) ? "arn:aws:iam::${data.aws_caller_identity.original_session.id}:role/MemberInfrastructureAccess" : null
  sign_aws_requests   = true
  # Health checks and sniffing assume direct node access; a managed domain sits
  # behind an endpoint, so both stay off.
  healthcheck = false
  sniff       = false
}
