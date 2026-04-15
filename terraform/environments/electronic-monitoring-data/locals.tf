#### This file can be used to store locals specific to the member account ####
locals {
  env_account_id = local.environment_management.account_ids[terraform.workspace]

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
