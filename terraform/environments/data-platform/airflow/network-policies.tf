# Kyverno's default-deny NetworkPolicy (generate-default-network-policy, owned by
# cluster) blocks all egress except DNS. Allow HTTPS out of the mwaa
# namespace to the AWS service endpoints that Airflow workflow IAM roles can use


locals {
  # Workflows run with AWS_DEFAULT_REGION=eu-west-1 (Analytical Platform data),
  # while Data Platform resources live in eu-west-2.
  mwaa_egress_aws_regions = ["eu-west-1", "eu-west-2"]


  mwaa_egress_aws_regional_services = [
    "athena",
    "bedrock",
    "bedrock-runtime",
    "glue",
    "kms",
    "lakeformation",
    "logs",       # CloudWatch Logs
    "monitoring", # CloudWatch metrics
    "s3",
    "secretsmanager",
    "sts", # IRSA AssumeRoleWithWebIdentity
    "textract",
  ]

  mwaa_egress_aws_fqdns = concat(
    [
      for pair in setproduct(local.mwaa_egress_aws_regional_services, local.mwaa_egress_aws_regions) :
      { matchName = "${pair[0]}.${pair[1]}.amazonaws.com" }
    ],
    # S3 virtual-hosted-style requests (<bucket>.s3.<region>.amazonaws.com)
    [for region in local.mwaa_egress_aws_regions : { matchPattern = "*.s3.${region}.amazonaws.com" }],
    # Global endpoints used by SDK defaults and S3 redirects
    [
      { matchName = "sts.amazonaws.com" },
      { matchName = "s3.amazonaws.com" },
      { matchPattern = "*.s3.amazonaws.com" },
    ],
  )
}

resource "kubernetes_manifest" "mwaa_allow_egress_aws" {
  manifest = {
    apiVersion = "cilium.io/v2"
    kind       = "CiliumNetworkPolicy"
    metadata = {
      name      = "mwaa-allow-egress-aws"
      namespace = kubernetes_namespace_v1.mwaa.metadata[0].name
    }
    spec = {
      endpointSelector = {}
      egress = [
        # DNS via CoreDNS through Cilium's DNS proxy, so Cilium learns the IPs
        # behind the FQDNs below. Required for toFQDNs to work.
        {
          toEndpoints = [
            {
              matchLabels = {
                "k8s:io.kubernetes.pod.namespace" = "kube-system"
                "k8s-app"                         = "coredns"
              }
            }
          ]
          toPorts = [
            {
              ports = [
                { port = "53", protocol = "UDP" },
                { port = "53", protocol = "TCP" },
              ]
              rules = {
                dns = [
                  { matchPattern = "*" }
                ]
              }
            }
          ]
        },
        # HTTPS to AWS service endpoints only
        {
          toFQDNs = local.mwaa_egress_aws_fqdns
          toPorts = [
            {
              ports = [
                { port = "443", protocol = "TCP" }
              ]
            }
          ]
        },
      ]
    }
  }
}
