#### This file can be used to store locals specific to the member account ####
locals {
  #----------------------------------------------------------------------------
  # CAPITA
  #----------------------------------------------------------------------------
  capita_ssh_keys = [
      "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBFc140uxPfjq1ilaOxcLYbnyIau2vURzKWFHLsxra+5Vf1nSZypOZ/g9eavBxcf2tkxBjgTx06BeRh3j+QhA8rnV9vKtyh9ZXIe5SNcrGlsGLKMyn+eB05Dt2m58oyMwWA==",
    ]
  capita_cidr_ipv4s = [
    "82.203.33.112/28",
    "82.203.33.128/28",
    "85.115.52.0/24",
    "85.115.53.0/24",
    "85.115.54.0/24",
  ]
  capita_cidr_ipv6s = []

  sftp_account_capita_test = {
    name       = "capita_test"
    ssh_keys   = local.capita_ssh_keys
    cidr_ipv4s = local.capita_cidr_ipv4s
    cidr_ipv6s = local.capita_cidr_ipv6s
  }
  
  sftp_account_capita_alcohol_monitoring = {
    name       = "alcohol_monitoring"
    ssh_keys   = local.capita_ssh_keys
    cidr_ipv4s = local.capita_cidr_ipv4s
    cidr_ipv6s = local.capita_cidr_ipv6s
  }

  sftp_account_capita_blob_storage = {
    name       = "blob_storage"
    ssh_keys   = local.capita_ssh_keys
    cidr_ipv4s = local.capita_cidr_ipv4s
    cidr_ipv6s = local.capita_cidr_ipv6s
  }

  sftp_account_capita_forms_and_subject_id = {
    name       = "forms_and_subject_id"
    ssh_keys   = local.capita_ssh_keys
    cidr_ipv4s = local.capita_cidr_ipv4s
    cidr_ipv6s = local.capita_cidr_ipv6s
  }

  #----------------------------------------------------------------------------
  # CIVICA
  #----------------------------------------------------------------------------
  civica_ssh_keys   = [
    "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBCJBwZM5nMigS31soM45PITAHCmyhQpdDAkdX1liqnIZSd8A+zn3XQyVRy5E2a39gfsng5hAQetDFJKn+SaayATCQAzN0cJWlcrvtv314UsRV+PxO236sWVf+RwguUDZRQ==",
  ]
  civica_cidr_ipv4s = [
    "20.0.26.153/32",
  ]
  civica_cidr_ipv6s = []

  sftp_account_civica_test = {
    name       = "civica_test"
    ssh_keys   = local.civica_ssh_keys
    cidr_ipv4s = local.civica_cidr_ipv4s
    cidr_ipv6s = local.civica_cidr_ipv6s
  }

  sftp_account_civica_orca = {
    name       = "orca"
    ssh_keys   = local.civica_ssh_keys
    cidr_ipv4s = local.civica_cidr_ipv4s
    cidr_ipv6s = local.civica_cidr_ipv6s
  }

  #----------------------------------------------------------------------------
  # G4S
  #----------------------------------------------------------------------------
  g4s_ssh_keys   = [
    "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBK85G9UwgU1KKgsYXfTWDsT4MqGSmjku1XGpH1EqmSuXLk5lmwFsgoLqqsROq2oEw2Yrr3uLyNVY2Dl6Pfm+dkdljfbPtqku+AkRSkhDo4K7bIwhWPh7HImcalxhde6BUA== ecdsa-key-20240208",
  ]
  g4s_cidr_ipv4s = [
    "18.135.195.129/32",
  ]
  g4s_cidr_ipv6s = []
  
  sftp_account_g4s_test = {
    name       = "g4s_test"
    ssh_keys   = local.g4s_ssh_keys
    cidr_ipv4s = local.g4s_cidr_ipv4s
    cidr_ipv6s = local.g4s_cidr_ipv6s
  }

  sftp_account_g4s_atrium = {
    name       = "atrium"
    ssh_keys   = local.g4s_ssh_keys
    cidr_ipv4s = local.g4s_cidr_ipv4s
    cidr_ipv6s = local.g4s_cidr_ipv6s
  }

  sftp_account_g4s_atv = {
    name       = "atv"
    ssh_keys   = local.g4s_ssh_keys
    cidr_ipv4s = local.g4s_cidr_ipv4s
    cidr_ipv6s = local.g4s_cidr_ipv6s
  }

  sftp_account_g4s_emsys_mvp = {
    name       = "emsys_mvp"
    ssh_keys   = local.g4s_ssh_keys
    cidr_ipv4s = local.g4s_cidr_ipv4s
    cidr_ipv6s = local.g4s_cidr_ipv6s
  }

  sftp_account_g4s_emsys_tpims = {
    name       = "emsys_tpims"
    ssh_keys   = local.g4s_ssh_keys
    cidr_ipv4s = local.g4s_cidr_ipv4s
    cidr_ipv6s = local.g4s_cidr_ipv6s
  }

  sftp_account_g4s_fep = {
    name       = "fep"
    ssh_keys   = local.g4s_ssh_keys
    cidr_ipv4s = local.g4s_cidr_ipv4s
    cidr_ipv6s = local.g4s_cidr_ipv6s
  }

  sftp_account_g4s_integrity = {
    name       = "integrity"
    ssh_keys   = local.g4s_ssh_keys
    cidr_ipv4s = local.g4s_cidr_ipv4s
    cidr_ipv6s = local.g4s_cidr_ipv6s
  }

  sftp_account_g4s_subject_history = {
    name       = "subject_history"
    ssh_keys   = local.g4s_ssh_keys
    cidr_ipv4s = local.g4s_cidr_ipv4s
    cidr_ipv6s = local.g4s_cidr_ipv6s
  }

  sftp_account_g4s_tasking = {
    name       = "tasking"
    ssh_keys   = local.g4s_ssh_keys
    cidr_ipv4s = local.g4s_cidr_ipv4s
    cidr_ipv6s = local.g4s_cidr_ipv6s
  }

  sftp_account_g4s_telephony = {
    name       = "telephony"
    ssh_keys   = local.g4s_ssh_keys
    cidr_ipv4s = local.g4s_cidr_ipv4s
    cidr_ipv6s = local.g4s_cidr_ipv6s
  }

  #----------------------------------------------------------------------------
  # DEVELOPERS
  #----------------------------------------------------------------------------
  sftp_account_dev = {
    name = "dev"
    ssh_keys   = [
      # Matt Price
      "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBA3BsCFaNiGxbmJffRi9q/W3aLmZWgqE6QkeFJD5O6F4nDdjsV1R0ZMUvTSoi3tKqoAE+1RYYj2Ra/F1buHov9e+sFPrlMl0wql6uMsBA1ndiIiKuq+NLY1NOxEvqm2J9Q==",
      # Matt Heery
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClyRRkvW162H2NQm5IlavjE4zBhnzGJ/V+raqe7ynPumIgKhmNto8GD6iKlWkzLGxfwXQhONM/9J8+u9tqncw5FzEWEYdX/FEJF5VwLYma/OtMUio3vtwsc9zbae4EyTvROvbJSMgL07ZicUjQ9pS4+pst2KVjDtgCXD8l7A66wOkmht2Cb2Ebfk+wk965uN5wE5vHDQBx6QQ4z9UiGEp34n/g2O9gUGUJcFdYCEHVl1MY+dicCJwsRzEC1a0s/LzCtiCo66yWW8VEpMpDJNCAJccxadwWBI1d+8R94LTUakxkYhAVCpzs+A/qjaAUKsT/1KQm0+3gJIfLqmWYUumB4VgP2+cYiFbdxWQt2lLAUYZmsTwR5EktCftA5OGcwKO11sKnouj+IYiN9wfRl8kQEs+KZDDSjXKAdsWvRwhRMbBZdLqIzO2InyLCQaujZqMupMh5KkmrhL9eYFn0qtWSG274vnmUacvaIl1e8EmIb9j5ksyVXysPlIVxbNks51E= matt.heery@MJ004484",
    ]
    cidr_ipv4s = [
      # fy nhy
      "46.69.144.146/32",
      # Petty France
      "81.134.202.29/32",
    ]
    cidr_ipv6s = []
  }
}
