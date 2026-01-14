#### This file can be used to store locals specific to the member account ####
locals {
  env_account_id = local.environment_management.account_ids[terraform.workspace]

  #----------------------------------------------------------------------------
  # BUDDI
  #----------------------------------------------------------------------------
  buddi_ssh_keys = [
    "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBIXoHoZO8V5tWMG9JRQtzkjPFEkVYKGP5cte0R9rkeeyGGUP6hUudKK9IsKaW6nn/4c+KMfZG8wyiSFYwzPuor86yjb8hH0q2dRClcPAS7FbAOu3rnBn+QBGzoP2ohJFUQ==",
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClMm3/4U32lRqOtLpgtne4Kqnl0PnchnUNRgiCKHC550zoGMOs+Vw7SzxFqgEHoPcDGU4l21cL8yu+1g0Eg+EBHGA+72EQH9gWqZr/eDjMCgp669CO5eo3bXQ4nL72obyRQyJPrDS3ytRLRGwNd37DsLngePEksDfc8Qv+65OlQ60CxRpXLMVpfR3d+WDFkVu33lX7X7K9xv7nvDPLGiynvjPQbsbx2z76GAjebdEQt5xf2d4+U6Sptpq8dxVhFFfoaIv8S/xMFkbjOy4k1zBllyisQIai/PVoeBtj2AVQgNyQclauVreyKfaMwRDiLDwG53ZdQ4fzSnFsdLYyjT2K+Uqd1S66Sa6pAiz8ciY6fZ0zdfNsl2IULir2+tiljYzPxPmPFGsk3XxBZVbEgTDHjtVBzvRlHSmEcUU5s7pZz8FtTg/RwrVQ6TAD0YBJoUlH3qPYCSeaBxCqrag7IVWNzua7u6Zym3U6LTGG96AdNZr+he/waq5L/z7lf0iCIss= kane@LAPTOP-Q1BUE8MA"
  ]
  buddi_cidr_ipv4s = [
    "81.179.159.7/32",
    "3.9.120.181/32"
  ]
  buddi_cidr_ipv6s = []

  sftp_account_buddi_test = {
    name       = "test"
    ssh_keys   = local.buddi_ssh_keys
    cidr_ipv4s = local.buddi_cidr_ipv4s
    cidr_ipv6s = local.buddi_cidr_ipv6s
  }

  sftp_account_buddi_live = {
    name       = "buddi"
    ssh_keys   = local.buddi_ssh_keys
    cidr_ipv4s = local.buddi_cidr_ipv4s
    cidr_ipv6s = local.buddi_cidr_ipv6s
  }

  #----------------------------------------------------------------------------
  # CIVICA
  #----------------------------------------------------------------------------
  civica_ssh_keys = [
    "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBBBXwsFkiYvUwkwadVYgAjSU3L+SyN7AZnWabN+HLLf66PZHagS653rIkbA7PEpZKydTvM3FLCdbKzTZac57AdTwoWArLLnSwWRUyNQRZ+omdbXaUqa8MM1n1gNBpynkIw==",
    "ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBDEMaR2/Fk/XjgxYMHyLarpeArHEaPB6vwKwFfMsw8mlZ3BR5MnE72ZOEIqD4WwN6d2Tnrok3Y7DNUQCv9D/Mh/JwG3NyMeM6uinbQMHzkmMQn6/cMTuY30I6XD5nt4h2A== ecdsa-key-20250930"
  ]
  civica_cidr_ipv4s = [
    "172.167.3.97/32",
  ]
  civica_cidr_ipv6s = []

  sftp_account_civica_test = {
    name       = "test"
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
  # DEVELOPERS
  #----------------------------------------------------------------------------
  sftp_account_dev = {
    name = "dev_access"
    ssh_keys = [
      # Matt Heery
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPo/IGYprUoZqGHzy6pgkSDKy4zY2+xYYWELaK5uMjK+2YIHm99vIVlEsqQIdrH/NlBIKxa97eDRBj3n5NMhrjg7g6hiuzqeJVKx21SBBhfMvFxHgrLWW8ZiaJ+PWHda5LH7BLW6QvMyh4dI/Jl26JvYLvnkXB5QA/MbaHxt59ueBjjxH/+877dHri41aGMqf01UjVCcBC2wqAUCngC3UZvtjbMVSkWlcyKIx8DI+YnThSVbfT7HxAMhbrcO296Ec/G7sfVHibr+pBHqGOSODkRVKezXCIi+UUBJ94c/p17eV+MlTAqvRKvxJ2rvd50UtDvwsTEYvJjptaTEtxY4az matt-heery",
      # Khristiania Raihan
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7+3IYrXHqSyLRRK0BN99P1rcDMLEDlPJAuImLBz2MH/PyWQp34FNUaxwlZ0QsrTaCzsKTde2JEE7KTNNe1b+Dcp6z0gz+9l9J2SoWZvQVUwrASwb3Ox2rfQFjh+ZjllslbZkYEpKr8Js53krCToTwi5gqXddwXTnxy6TMdGjfVRRrWQqYGVUJYd5vbw7vnqUDqtnb0J6pLsQdh5X0j10a9yfjggwzrzCgrMDtKUMxJQpB3c596kf1Uzf05U+F9M10/CcByRSNBzU1NAsLpNH9xUPYOP/KYTFoIBdnaPF4ePDL6SnHWUzbp0CkGM8Izp/jZkZuCuKe5yGgHztBskt5qduc3EmI0E2yYcnqGMooCDC2k3WMt+GBc5StctnhlcvtTK+Yr35ij3GrO5hpgO/jv4LJe3jUIdztLQJ1cPiFqoG1SgW9SdtVrEweLDR12N0fngLDrI0VaI4xxylybeXn8q3+6UAUdJPoOM5M1D7tokw8Ug44r3gLXLT6n1VkbLforu0aeQYObWli8f/HtSVezbbNY/29o/QF+ye3fsZ4TxAlwu/K8Gxg0x7lh4YtBbjyuFGEuCIWGSbF4jg9gdfsFv2ST3X70+TrgDja9G+Lx6jac4W6VTTQs6XgyA5uLqHBBf4SJoX8DaQZmAEZwtLVWE/9pS7vQl6QYiJm4UZTfw== khristiania.raihan@justice.gov.uk",
    ]
    cidr_ipv4s = [
      # 10 SC
      "51.149.2.6/32",
      # Petty France
      "213.121.161.124/32",
      # SCRAM DEV
      "3.9.254.251/32",
    ]
    cidr_ipv6s = []
  }
}
