# =============================================================================
# USED BY: moj-analytical-services runners ONLY (21 runners: airflow, cadet, dpr, emds, ...)
# K8s secret "actions-runners-token-apc-self-hosted-runners" (key "token")
# -> GITHUB_TOKEN in the runner pod, used to REGISTER the runner (chart default tokenSecretName).
#   OLD: PAT 4282353 (module.actions_runners_token_apc_self_hosted_runners_secret).
#   NEW: GitHub App installation token minted by actions_runners_mojas_registration_token_generator
#        (re-minted every 30 min; tokens are valid 60 min).
# =============================================================================
resource "kubernetes_manifest" "actions_runners_token_apc_self_hosted_runners_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "actions-runners-token-apc-self-hosted-runners"
      "namespace" = kubernetes_namespace_v1.actions_runners[0].metadata[0].name
    }
    "spec" = {
      "refreshInterval" = "30m"
      "target" = {
        "name" = "actions-runners-token-apc-self-hosted-runners"
      }
      "dataFrom" = [
        {
          "sourceRef" = {
            "generatorRef" = {
              "apiVersion" = "generators.external-secrets.io/v1alpha1"
              "kind"       = "GithubAccessToken"
              "name"       = "actions-runners-mojas-registration-token"
            }
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.actions_runners_mojas_registration_token_generator]
}

# =============================================================================
# USED BY: data-catalogue runner ONLY (ministryofjustice/data-catalogue).
# K8s secret "actions-runners-token-moj-apc-self-hosted-runners" (key "token")
# -> GITHUB_TOKEN in the runner pod, used to REGISTER the runner
#    (set via tokenSecretName in src/helm/values/actions-runners/data-catalogue/values.yml.tftpl).
#   OLD: PAT 5605162 (module.actions_runners_token_moj_apc_self_hosted_runners_secret).
#   NEW: GitHub App installation token minted by actions_runners_moj_registration_token_generator
#        (re-minted every 30 min; tokens are valid 60 min).
# =============================================================================
resource "kubernetes_manifest" "actions_runners_token_moj_apc_self_hosted_runners_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "actions-runners-token-moj-apc-self-hosted-runners"
      "namespace" = kubernetes_namespace_v1.actions_runners[0].metadata[0].name
    }
    "spec" = {
      "refreshInterval" = "30m"
      "target" = {
        "name" = "actions-runners-token-moj-apc-self-hosted-runners"
      }
      "dataFrom" = [
        {
          "sourceRef" = {
            "generatorRef" = {
              "apiVersion" = "generators.external-secrets.io/v1alpha1"
              "kind"       = "GithubAccessToken"
              "name"       = "actions-runners-moj-registration-token"
            }
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.actions_runners_moj_registration_token_generator]
}

# =============================================================================
# USED BY: ALL runners - moj-analytical-services (21) AND data-catalogue.
# K8s secret "actions-runners-github-app-apc-self-hosted-runners"
# -> "private-key" is used by KEDA (TriggerAuthentication appKey) to SCALE runner pods.
# =============================================================================
resource "kubernetes_manifest" "actions_runners_github_app_apc_self_hosted_runners_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "actions-runners-github-app-apc-self-hosted-runners"
      "namespace" = kubernetes_namespace_v1.actions_runners[0].metadata[0].name
    }
    "spec" = {
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "actions-runners-github-app-apc-self-hosted-runners"
      }
      "data" = [
        {
          "remoteRef" = {
            "key"      = module.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_id
            "property" = "app_id"
          }
          "secretKey" = "app-id"
        },
        {
          "remoteRef" = {
            "key"      = module.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_id
            "property" = "client_id"
          }
          "secretKey" = "client-id"
        },
        {
          "remoteRef" = {
            "key"      = module.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_id
            "property" = "installation_id"
          }
          "secretKey" = "installation-id" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
        {
          "remoteRef" = {
            "key"              = module.actions_runners_github_app_apc_self_hosted_runners_secret[0].secret_id
            "property"         = "private_key"
            "decodingStrategy" = "Base64"
          }
          "secretKey" = "private-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
      ]
    }
  }
}

# =============================================================================
#  USED BY: moj-analytical-services runners ONLY.
# Registration App private key -> K8s secret "actions-runners-github-app-mojas-registration".
# Read only by actions_runners_mojas_registration_token_generator.
# Literal key name (not module output) so the plan works before the secret exists.
# =============================================================================
resource "kubernetes_manifest" "actions_runners_github_app_mojas_registration_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "actions-runners-github-app-mojas-registration"
      "namespace" = kubernetes_namespace_v1.actions_runners[0].metadata[0].name
    }
    "spec" = {
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "actions-runners-github-app-mojas-registration"
      }
      "data" = [
        {
          "remoteRef" = {
            "key"              = "actions-runners/app/mojas-registration-apc-self-hosted-runners"
            "property"         = "private_key"
            "decodingStrategy" = "Base64"
          }
          "secretKey" = "private-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
      ]
    }
  }

  depends_on = [module.actions_runners_github_app_mojas_registration_secret]
}

# =============================================================================
# USED BY: moj-analytical-services runners ONLY.
# GithubAccessToken generator - mints installation tokens (valid 60 min) from the
# moj-analytical-services registration App. Token permissions = App permissions.
# appID / installID: from Secrets Manager, via data source.
# tostring(): the data source can be unknown at plan time on a fresh state.
# =============================================================================
resource "kubernetes_manifest" "actions_runners_mojas_registration_token_generator" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  manifest = {
    "apiVersion" = "generators.external-secrets.io/v1alpha1"
    "kind"       = "GithubAccessToken"
    "metadata" = {
      "name"      = "actions-runners-mojas-registration-token"
      "namespace" = kubernetes_namespace_v1.actions_runners[0].metadata[0].name
    }
    "spec" = {
      "appID"        = tostring(jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_mojas_registration_secret[0].secret_string)["app_id"])
      "installID"    = tostring(jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_mojas_registration_secret[0].secret_string)["installation_id"])
      "repositories" = ["airflow", "airflow-create-a-pipeline", "create-a-derived-table"]
      "auth" = {
        "privateKey" = {
          "secretRef" = {
            "name" = "actions-runners-github-app-mojas-registration"
            "key"  = "private-key"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.actions_runners_github_app_mojas_registration_secret]
}

# =============================================================================
#  USED BY: data-catalogue runner ONLY.
# Registration App private key -> K8s secret "actions-runners-github-app-moj-registration".
# Read only by actions_runners_moj_registration_token_generator.
# Literal key name (not module output) so the plan works before the secret exists.
# =============================================================================
resource "kubernetes_manifest" "actions_runners_github_app_moj_registration_secret" {
  #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  manifest = {
    "apiVersion" = "external-secrets.io/v1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "actions-runners-github-app-moj-registration"
      "namespace" = kubernetes_namespace_v1.actions_runners[0].metadata[0].name
    }
    "spec" = {
      "refreshInterval" = "1m"
      "secretStoreRef" = {
        "kind" = "ClusterSecretStore"
        "name" = "aws-secretsmanager"
      }
      "target" = {
        "name" = "actions-runners-github-app-moj-registration"
      }
      "data" = [
        {
          "remoteRef" = {
            "key"              = "actions-runners/app/moj-registration-apc-self-hosted-runners"
            "property"         = "private_key"
            "decodingStrategy" = "Base64"
          }
          "secretKey" = "private-key" #checkov:skip=CKV_SECRET_6:secretKey is a reference to the key in the secret
        },
      ]
    }
  }

  depends_on = [module.actions_runners_github_app_moj_registration_secret]
}

# =============================================================================
#  USED BY: data-catalogue runner ONLY.
# GithubAccessToken generator - mints installation tokens (valid 60 min) from the
# data-catalogue registration App. Token permissions = App permissions.
# appID / installID: from Secrets Manager, via data source.
# tostring(): the data source can be unknown at plan time on a fresh state.
# =============================================================================
resource "kubernetes_manifest" "actions_runners_moj_registration_token_generator" {
  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  manifest = {
    "apiVersion" = "generators.external-secrets.io/v1alpha1"
    "kind"       = "GithubAccessToken"
    "metadata" = {
      "name"      = "actions-runners-moj-registration-token"
      "namespace" = kubernetes_namespace_v1.actions_runners[0].metadata[0].name
    }
    "spec" = {
      "appID"        = tostring(jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_moj_registration_secret[0].secret_string)["app_id"])
      "installID"    = tostring(jsondecode(data.aws_secretsmanager_secret_version.actions_runners_github_app_moj_registration_secret[0].secret_string)["installation_id"])
      "repositories" = ["data-catalogue"]
      "auth" = {
        "privateKey" = {
          "secretRef" = {
            "name" = "actions-runners-github-app-moj-registration"
            "key"  = "private-key"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.actions_runners_github_app_moj_registration_secret]
}