# This file is used to import the existing k8s reesources and iam polcies into Terraform state.Will be deleted after the import is complete and the state file is updated.

#### NAMESPACES ######
# external secrets 
import {
  to = kubernetes_cluster_role_v1.mwaa_external_secrets
  id = "mwaa-external-secrets"
}

removed {
  from = kubernetes_cluster_role.mwaa_external_secrets
  lifecycle {
    destroy = false
  }
}

# role bindings
import {
  to = kubernetes_cluster_role_binding_v1.mwaa_external_secrets
  id = "mwaa-external-secrets"
}

removed {
  from = kubernetes_cluster_role_binding.mwaa_external_secrets
  lifecycle {
    destroy = false
  }
}

# aws_observability namespaces
import {
  to = kubernetes_namespace_v1.aws_observability
  id = "aws-observability"
}

removed {
  from = kubernetes_namespace.aws_observability
  lifecycle {
    destroy = false
  }
}

# certt-manager namespaces
import {
  to = kubernetes_namespace_v1.cert_manager
  id = "cert-manager"
}

removed {
  from = kubernetes_namespace.cert_manager
  lifecycle {
    destroy = false
  }
}

# autoscaler namespaces
import {
  to = kubernetes_namespace_v1.cluster_autoscaler
  id = "cluster-autoscaler"
}
removed {
  from = kubernetes_namespace.cluster_autoscaler
  lifecycle {
    destroy = false
  }
}

# external dns namespaces
import {
  to = kubernetes_namespace_v1.external_dns
  id = "external-dns"
}
removed {
  from = kubernetes_namespace.external_dns
  lifecycle {
    destroy = false
  }
}

#external secrets namespaces
import {
  to = kubernetes_namespace_v1.external_secrets
  id = "external-secrets"
}
removed {
  from = kubernetes_namespace.external_secrets
  lifecycle {
    destroy = false
  }
}

#ingress_nginx namespaces
import {
  to = kubernetes_namespace_v1.ingress_nginx
  id = "ingress-nginx"
}
removed {
  from = kubernetes_namespace.ingress_nginx
  lifecycle {
    destroy = false
  }
}

#karpenter namespaces
import {
  to = kubernetes_namespace_v1.karpenter
  id = "karpenter"
}
removed {
  from = kubernetes_namespace.karpenter
  lifecycle {
    destroy = false
  }
}

#keda namespaces
import {
  to = kubernetes_namespace_v1.keda
  id = "keda"
}
removed {
  from = kubernetes_namespace.keda
  lifecycle {
    destroy = false
  }
}

#kyverno namespaces
import {
  to = kubernetes_namespace_v1.kyverno
  id = "kyverno"
}
removed {
  from = kubernetes_namespace.kyverno
  lifecycle {
    destroy = false
  }
}

# velero namespaces
import {
  to = kubernetes_namespace_v1.velero
  id = "velero"
}
removed {
  from = kubernetes_namespace.velero
  lifecycle {
    destroy = false
  }
}

#storage class
import {
  to = kubernetes_storage_class_v1.gp3
  id = "gp3"
}
removed {
  from = kubernetes_storage_class.gp3
  lifecycle {
    destroy = false
  }
}
