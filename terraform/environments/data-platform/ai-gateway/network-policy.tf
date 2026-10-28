locals {
  ai_gateway_bedrock_regions = toset([
    for model in values(try(local.ai_gateway_models_filtered.amazon_bedrock, {})) : model.region
  ])

  ai_gateway_google_locations = toset([
    for model in values(try(local.ai_gateway_models_filtered.google_gemini_enterprise_agent_platform, {})) : model.location
  ])

  ai_gateway_database_fqdns = distinct(compact(concat(
    [module.ai_gateway_aurora.cluster_endpoint],
    local.has_reader ? [module.ai_gateway_aurora.cluster_reader_endpoint] : []
  )))

  ai_gateway_microsoft_foundry_endpoint = try(
    regex("^https?://([^/:]+)", jsondecode(data.aws_secretsmanager_secret_version.microsoft_foundry_jedi_gateway.secret_string)["endpoint"])[0],
    null
  )

  # Kept out of distinct() so the secret-derived host doesn't mask the whole allowlist in plans
  ai_gateway_microsoft_foundry_fqdns = nonsensitive(local.ai_gateway_microsoft_foundry_endpoint != null) ? [local.ai_gateway_microsoft_foundry_endpoint] : []

  ai_gateway_https_egress_fqdns = concat(
    distinct(concat(
      [for region in local.ai_gateway_bedrock_regions : "bedrock-runtime.${region}.amazonaws.com"],
      [
        "sts.${data.aws_region.current.region}.amazonaws.com",
        "${module.audit_logs.s3_bucket_id}.s3.${data.aws_region.current.region}.amazonaws.com",
        "truststore.pki.rds.amazonaws.com", # CA bundle for the rds_iam grant job
      ],
      # Batch inference management and S3 endpoints
      local.ai_gateway_batch_storage == null ? [] : [
        "bedrock.${local.ai_gateway_bedrock_batch_region}.amazonaws.com",
        "bedrock-runtime.${local.ai_gateway_bedrock_batch_region}.amazonaws.com",
        "s3.${local.ai_gateway_batch_storage.region}.amazonaws.com",
        "${local.ai_gateway_batch_storage.input_bucket_name}.s3.${local.ai_gateway_batch_storage.region}.amazonaws.com",
        "${local.ai_gateway_batch_storage.output_bucket_name}.s3.${local.ai_gateway_batch_storage.region}.amazonaws.com",
      ],
      [
        "sts.googleapis.com",
        "iamcredentials.googleapis.com",
        "cloudresourcemanager.googleapis.com", # google-auth project ID lookup
      ],
      [
        for location in local.ai_gateway_google_locations : (
          location == "global" ? "aiplatform.googleapis.com" :
          location == "eu" ? "aiplatform.eu.rep.googleapis.com" :
          "${location}-aiplatform.googleapis.com"
        )
      ],
      [
        "login.microsoftonline.com",
        "graph.microsoft.com", # Admin UI SSO profile and groups
      ],
      # LiteLLM model cost map and Node.js runtime bootstrap
      [
        "raw.githubusercontent.com",
        "nodejs.org",
      ]
    )),
    local.ai_gateway_microsoft_foundry_fqdns
  )

  ai_gateway_dns_match_rules = concat(
    [
      for fqdn in concat(
        local.ai_gateway_https_egress_fqdns,
        local.ai_gateway_database_fqdns,
        [module.ai_gateway_elasticache.replication_group_primary_endpoint_address]
      ) : { matchName = fqdn }
    ],
    # Search-path candidates; refusing them makes musl resolvers fail before the absolute lookup
    [
      { matchPattern = "**.cluster.local" },
      { matchPattern = "**.${data.aws_region.current.region}.compute.internal" },
    ]
  )
}

resource "kubernetes_manifest" "ai_gateway_egress_policy" {
  count = local.environment_configuration.ai_gateway_egress_policy_enabled ? 1 : 0

  depends_on = [module.ai_gateway_namespace]

  manifest = {
    apiVersion = "cilium.io/v2"
    kind       = "CiliumNetworkPolicy"
    metadata = {
      name      = "ai-gateway-egress"
      namespace = module.ai_gateway_namespace.name
    }
    spec = {
      description      = "Egress allowlist for ai-gateway pods, managed in terraform/environments/data-platform/ai-gateway"
      endpointSelector = {}
      egress = [
        {
          toEndpoints = [
            {
              matchLabels = {
                "k8s:io.kubernetes.pod.namespace" = "kube-system"
                "k8s:k8s-app"                     = "coredns"
              }
            }
          ]
          toPorts = [
            {
              ports = [
                { port = "53", protocol = "UDP" },
                { port = "53", protocol = "TCP" }
              ]
              rules = {
                dns = local.ai_gateway_dns_match_rules
              }
            }
          ]
        },
        {
          toFQDNs = [
            for fqdn in local.ai_gateway_https_egress_fqdns : { matchName = fqdn }
          ]
          toPorts = [
            {
              ports = [{ port = "443", protocol = "TCP" }]
            }
          ]
        },
        {
          toFQDNs = [
            for fqdn in local.ai_gateway_database_fqdns : { matchName = fqdn }
          ]
          toPorts = [
            {
              ports = [{ port = tostring(module.ai_gateway_aurora.cluster_port), protocol = "TCP" }]
            }
          ]
        },
        {
          toFQDNs = [
            { matchName = module.ai_gateway_elasticache.replication_group_primary_endpoint_address }
          ]
          toPorts = [
            {
              ports = [{ port = tostring(module.ai_gateway_elasticache.replication_group_port), protocol = "TCP" }]
            }
          ]
        }
      ]
    }
  }
}