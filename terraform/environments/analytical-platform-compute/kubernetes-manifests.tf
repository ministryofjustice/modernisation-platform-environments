resource "kubernetes_manifest" "prometheus_operator_crds" {
  for_each = data.http.prometheus_operator_crds

  manifest = yamldecode(each.value.response_body)
}
