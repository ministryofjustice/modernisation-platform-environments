locals {
  environment_configurations = {
    development = {

      /* managed_prometheus_kms_access_iam_policy_arn */
      managed_prometheus_kms_access_iam_policy_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-compute-development"]}:policy/managed-prometheus-kms-access20240521093109516600000001"

      /* Network Monitoring */
      cloud_platform_endpoints     = {}
      hmcts_sdp_endpoints          = {}
      hmcts_sdp_onecrown_endpoints = {}
    }
    test = {

      /* managed_prometheus_kms_access_iam_policy_arn */
      managed_prometheus_kms_access_iam_policy_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-compute-test"]}:policy/managed-prometheus-kms-access20240521093123650600000001"

      /* Network Monitoring */
      cloud_platform_endpoints = {
        non-prod = {
          destination      = "ingress.internal-non-prod.cloud-platform.service.justice.gov.uk"
          destination_port = "443"
        }
        prod = {
          destination      = "ingress.internal.cloud-platform.service.justice.gov.uk"
          destination_port = "443"
        }
      }

      hmcts_sdp_endpoints = {
        mipersistentithc-blob = {
          destination      = "10.168.4.13"
          destination_port = 443
        }
        miexportithc-blob = {
          destination      = "10.168.4.5"
          destination_port = 443
        }
        mipersistentstg-blob = {
          destination      = "10.168.3.8"
          destination_port = 443
        }
        miexportstg-blob = {
          destination      = "10.168.3.7"
          destination_port = 443
        }
        mipersistentprod-blob = {
          destination      = "10.168.5.13"
          destination_port = 443
        }
        miexportprod-blob = {
          destination      = "10.168.5.8"
          destination_port = 443
        }
        baisbaumojapnle-blob = {
          destination      = "10.225.251.100"
          destination_port = 443
        }
        baisbaumojapprod-blob = {
          destination      = "10.224.251.100"
          destination_port = 443
        }
        miadhoclandingprod-blob = {
          destination      = "10.168.5.4"
          destination_port = 443
        }
      }

      hmcts_sdp_onecrown_endpoints = {
        mi-synapse-dev-sql = {
          destination      = "10.168.1.14"
          destination_port = 1433
        }
        mi-synapse-prod-sql = {
          destination      = "10.168.5.16"
          destination_port = 1433
        }
      }
    }
    production = {

      /* managed_prometheus_kms_access_iam_policy_arn */
      managed_prometheus_kms_access_iam_policy_arn = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-compute-production"]}:policy/managed-prometheus-kms-access20240522102621280000000012"

      /* Network Monitoring */
      cloud_platform_endpoints = {
        non-prod = {
          destination      = "ingress.internal-non-prod.cloud-platform.service.justice.gov.uk"
          destination_port = "443"
        }
        prod = {
          destination      = "ingress.internal.cloud-platform.service.justice.gov.uk"
          destination_port = "443"
        }
      }

      hmcts_sdp_endpoints = {
        mipersistentithc-blob = {
          destination      = "10.168.4.13"
          destination_port = 443
        }
        miexportithc-blob = {
          destination      = "10.168.4.5"
          destination_port = 443
        }
        mipersistentstg-blob = {
          destination      = "10.168.3.8"
          destination_port = 443
        }
        miexportstg-blob = {
          destination      = "10.168.3.7"
          destination_port = 443
        }
        mipersistentprod-blob = {
          destination      = "10.168.5.13"
          destination_port = 443
        }
        miexportprod-blob = {
          destination      = "10.168.5.8"
          destination_port = 443
        }
        baisbaumojapnle-blob = {
          destination      = "10.225.251.100"
          destination_port = 443
        }
        baisbaumojapprod-blob = {
          destination      = "10.224.251.100"
          destination_port = 443
        }
        miadhoclandingprod-blob = {
          destination      = "10.168.5.4"
          destination_port = 443
        }
      }

      hmcts_sdp_onecrown_endpoints = {
        mi-synapse-dev-sql = {
          destination      = "10.168.1.14"
          destination_port = 1433
        }
        mi-synapse-prod-sql = {
          destination      = "10.168.5.16"
          destination_port = 1433
        }
      }
    }
  }
}
