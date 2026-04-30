moved {
  from = random_password.litellm_secret_key[0]
  to   = random_password.litellm_secret_key
}

moved {
  from = module.litellm_license_secret[0]
  to   = module.litellm_license_secret
}

moved {
  from = module.litellm_entra_id_secret[0]
  to   = module.litellm_entra_id_secret
}

moved {
  from = module.justiceai_azure_openai_secret[0]
  to   = module.justiceai_azure_openai_secret
}

moved {
  from = module.azure_openai_secret[0]
  to   = module.azure_openai_secret
}

moved {
  from = kubernetes_secret.litellm_master_key[0]
  to   = kubernetes_secret.litellm_master_key_cloud_platform[0]
}

moved {
  from = kubernetes_secret.litellm_license[0]
  to   = kubernetes_secret.litellm_license_cloud_platform[0]
}

moved {
  from = kubernetes_secret.litellm_entra_id[0]
  to   = kubernetes_secret.litellm_entra_id_cloud_platform[0]
}

moved {
  from = kubernetes_secret.justiceai_azure_openai[0]
  to   = kubernetes_secret.justiceai_azure_openai_cloud_platform[0]
}

moved {
  from = kubernetes_secret.azure_openai[0]
  to   = kubernetes_secret.azure_openai_cloud_platform[0]
}

moved {
  from = kubernetes_ingress_v1.litellm[0]
  to   = kubernetes_ingress_v1.litellm_cloud_platform[0]
}

moved {
  from = helm_release.litellm[0]
  to   = helm_release.litellm_cloud_platform[0]
}

moved {
  from = module.iam_role[0]
  to   = module.iam_role_cloud_platform[0]
}
