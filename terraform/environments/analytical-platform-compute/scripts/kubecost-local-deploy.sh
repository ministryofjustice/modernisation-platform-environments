#!/usr/bin/env bash

# helm template \
#   --namespace kubecost \
#   --values src/helm/values/kubecost/amp-integration.yaml \
#   --values src/helm/values/kubecost/eks-cost-monitoring.yaml \
#   kubecost-cost-analyzer \
#   oci://public.ecr.aws/kubecost/cost-analyzer --version 2.2.5

helm upgrade --install \
  --namespace kubecost \
  --values src/helm/values/kubecost/amp-integration.yaml \
  --values src/helm/values/kubecost/eks-cost-monitoring.yaml \
  --values src/helm/values/kubecost/extra.yaml \
  kubecost-cost-analyzer \
  oci://public.ecr.aws/kubecost/cost-analyzer --version 2.2.5