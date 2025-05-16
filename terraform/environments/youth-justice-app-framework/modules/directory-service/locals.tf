locals {
  ds_managed_ad_type               = "MicrosoftAD"    # Static input to force only MAD deployments
  ds_managed_ad_admin_secret_sufix = "admin_secret_2" #checkov:skip=CKV_SECRET_6: Ignore this
  environment_name                 = "${var.project_name}-${var.environment}"
}
