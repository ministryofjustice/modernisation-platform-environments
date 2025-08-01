locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      /* VPC */
      connected_vpc_cidr            = "10.26.128.0/23"
      connected_vpc_private_subnets = ["10.26.128.0/26", "10.26.128.64/26", "10.26.128.128/26"]
      connected_vpc_public_subnets  = ["10.26.129.0/26", "10.26.129.64/26", "10.26.129.128/26"]

      isolated_vpc_cidr                   = "10.0.0.0/16"
      isolated_vpc_private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      isolated_vpc_public_subnets         = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
      isolated_vpc_enable_nat_gateway     = true
      isolated_vpc_one_nat_gateway_per_az = true

      /* Transit Gateway */
      transit_gateway_routes = [
        /* Send all traffic not destined for local down to the transit gateway */
        "10.0.0.0/8"
      ]

      /* Image Versions */
      scan_image_version     = "0.1.6"
      transfer_image_version = "0.0.21"
      notify_image_version   = "0.0.22"

      /* Target Buckets */
      target_buckets              = ["mojap-land-dev"]
      datasync_target_buckets     = ["mojap-land-dev"]
      datasync_opg_target_buckets = ["mojap-data-production-datasync-opg-ingress-development"]

      /* Target KMS */
      target_kms_keys                = []
      mojap_land_kms_key             = "arn:aws:kms:eu-west-1:${local.environment_management.account_ids["analytical-platform-data-production"]}:key/8c53fbac-3106-422a-8f3d-409bb3b0c94d"
      datasync_opg_target_bucket_kms = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["analytical-platform-data-production"]}:key/38cf3d55-b36d-43e8-b91b-6b239a60cbea"

      /* Transfer Server */
      transfer_server_hostname = "sftp.development.ingestion.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users = {
        "opg-restore-ocr" = {
          ssh_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCWz7ue/saomMAKrVgo6FifjpGQfl7B4fs2s/MJa2jhpBVWXk9tquGDXp1/Yfk4C7FIneGKfh8fWHz9FPS+u6h3a9hMW8d/5onNuSr9S6T2mN7ydZQzGez5qyG2vNFLyip3ls6mQjIpXSo2aow7+3Y2lbDe8UamiYNVgvvWB+hVl5RJjcaReDDbi0xwdjGjep0LcvgAyKa8evmcEbFVkrLhWyc30xn1+OesqPWSpoIb/IlBDFxCqR46GW/zlOldEIatONhXWgvJ6dS5T1YmHsE4U0Py3BV8O5zvc+XRYjr/3w9LOwmTHS1xbzlhNBjO1o6O9hSBsowBjsWLL5aNWcdBH0DiWfIWkoq9Fy8VEAa/T5v7GCaKvDs9pGBpjQSQsWyKXbwP0Z2RGyU2CSGVzMM6gzrjaxanOK9QbLOqCpTSSIYWfokt+MNrHcQU+9mBTjq20URF7RW6tsM8GvzGRNk0hlkX3ueq86uLpQzRctGBTjN74qBba0WbauIcSl4OIrc+NEwjaFTmuIs0NIG5aoAop8WHOC8cxFAST2XjMF30eEh6/W9Gh0uPor4L5tUqJ/JuI2wcfYLuk1KLDcOUVin79QficX93zbaTPNXWW052ct50B0KnCmZyvQORwOH8gBFgkFe5MO/bqevG9Xpof/QvpCLKEON/fBAW4bEdIIv5qw=="
          cidr_blocks = ["51.11.176.157/32"]
        }
      }
      transfer_server_sftp_users_with_egress = {
        "essex-police" = {
          ssh_key               = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpNyYzfbqmy4QkViLRyASRqxrEK7G34o3Bc6Jdp8vK555/oBuAUXUxfavtenZnxuxdxsrBYBSCBFcU4+igeXN/nN2kVfaUlt1xBZBCRUaajinhmt+3CLbr8bWmHR/5vL/DhxHH+j/+gDH5A244XN/ybZQvCGX/ilgKiae8s0tiOZD2hmX0fhRTCohQFG/DIu06gqKIyxUQoHBoBJxjzaDvjqioJgqmD9893DN+Gx1KozmaQWHM+0f7iK1UFp8BkdeFBVkj8TOfx60o/EmAjWQ/U+WSHblaXo0nI+LQKZYkW52uTEnfSkbkyvs/vj8E8+vagwYi0noyTVmb5qReSuk1kyuqEP2ycKIaWKt+Z4LnwxHm7KO51SMMeBgpiFHaUTQWXZHYuU2aXVfFIgJkCtHdEjG7Qe2P8K5XU5rG+CrQ/Y9PxPrKQHk+2nox9dLfCWo2Eho1N85z9/rA7A0oNwsHkjWAl3k87lWdpg7y3VNLzqsMNF4M4HjpQV60MH73dUU= essex-police@kpvmshift04app.netr.ecis.police.uk"
          cidr_blocks           = ["194.74.29.178/32"]
          egress_bucket         = module.bold_egress_bucket.s3_bucket_id
          egress_bucket_kms_key = module.s3_bold_egress_kms.key_arn
        }
      }

      /* DataSync */
      datasync_instance_private_ip = "10.26.128.5"
    }
    production = {
      /* VPC */
      connected_vpc_cidr            = "10.27.128.0/23"
      connected_vpc_private_subnets = ["10.27.128.0/26", "10.27.128.64/26", "10.27.128.128/26"]
      connected_vpc_public_subnets  = ["10.27.129.0/26", "10.27.129.64/26", "10.27.129.128/26"]

      isolated_vpc_cidr                   = "10.0.0.0/16"
      isolated_vpc_private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      isolated_vpc_public_subnets         = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
      isolated_vpc_enable_nat_gateway     = true
      isolated_vpc_one_nat_gateway_per_az = true

      /* Transit Gateway */
      transit_gateway_routes = [
        /* Send all traffic not destined for local down to the transit gateway */
        "10.0.0.0/8"
      ]

      /* Image Versions */
      scan_image_version     = "0.1.6"
      transfer_image_version = "0.0.21"
      notify_image_version   = "0.0.22"

      /* Target Buckets */
      target_buckets = [
        "mojap-land",
        "mojap-data-production-shared-services-client-team-gov-29148"
      ]
      datasync_target_buckets     = ["mojap-land"]
      datasync_opg_target_buckets = ["mojap-data-production-datasync-opg-ingress-production"]

      laa_data_analysis_target_buckets = [
        "mojap-data-production-datasync-laa-ingress-production"
      ]

      /* Target KMS */
      target_kms_keys = [
        "arn:aws:kms:eu-west-2:593291632749:key/62503ba6-316e-473d-ae4b-042f8420dd07" # s3/mojap-data-production-shared-services-client-team-gov-29148
      ]
      mojap_land_kms_key                  = "arn:aws:kms:eu-west-1:${local.environment_management.account_ids["analytical-platform-data-production"]}:key/2855ac30-4e14-482e-85ca-53258e01f64c"
      datasync_opg_target_bucket_kms      = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["analytical-platform-data-production"]}:key/96eb04fe-8393-402c-b1f9-71fcece99e75"
      laa_data_analysis_target_bucket_kms = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["analytical-platform-data-production"]}:key/fe4674f4-52dc-4b73-a7c5-259c282742ba"

      /* Transfer Server */
      transfer_server_hostname = "sftp.ingestion.analytical-platform.service.justice.gov.uk"
      transfer_server_sftp_users = {
        "sscl-chris-j" = {
          ssh_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAx1BrX2NaosOZiGrfvuMYU08aycG/IlBO9FuZFAnXjLTGzw7BABkEJgCG6BHQydJymQIVNxhM9558p/l3CuAA7ItXncRLNNZ4eSLs2x81amEujV7KOuan28LSKU4yd5K+bCUOnpq35w0XEeYrwvEUHgrlR75FWumrus3rpv7xSbz4+7YqtweVOREUNew8Md/1jJpr26CHgn1VqtLKWzUOVU/UjKlKhr+dH7CbFGaux0Le+ntvD04TL91fx3yGFBN23Ybw+epGNhVFlPKuFfr++SDbF5M22jFu1lMtL96CPEVgTMYgcwRLeX51CrykmezFq1YEY//w2JDw8PKbDYF2ouLZLexh0M9l95VvejNNGx2BIEkfblXH8zWIWPu6D9ju6HOzucqKTctjLioZGVoaBwZA8MG8KvS887+4R611VNxZ05PxGJiIqWAcwgDKl91uFuzOkWXmoWXALqyI/QEMO5CU3JoUsZhHY4+eEnxyIoN1xqB4XSUwsvY0/hRZs2bvnTgKIPkwjqckhytpuTT6L8oAhSLDaUyBhy216pIBgq0EFRpStdLa2R3PQrrXalxl4ooyz3AeshnIUi4WslXRnw7/WUcgOeV5i8jqQmygvLlLjAtyAT+zsC0ItXsDzrovN9dpTTHmsPwr3ZGM9TmdrVZC7h3ZOkbrckhfVLtE8wU="
          cidr_blocks = ["51.140.183.67/32"]
        }
        "opg-restore-ocr" = {
          ssh_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCWz7ue/saomMAKrVgo6FifjpGQfl7B4fs2s/MJa2jhpBVWXk9tquGDXp1/Yfk4C7FIneGKfh8fWHz9FPS+u6h3a9hMW8d/5onNuSr9S6T2mN7ydZQzGez5qyG2vNFLyip3ls6mQjIpXSo2aow7+3Y2lbDe8UamiYNVgvvWB+hVl5RJjcaReDDbi0xwdjGjep0LcvgAyKa8evmcEbFVkrLhWyc30xn1+OesqPWSpoIb/IlBDFxCqR46GW/zlOldEIatONhXWgvJ6dS5T1YmHsE4U0Py3BV8O5zvc+XRYjr/3w9LOwmTHS1xbzlhNBjO1o6O9hSBsowBjsWLL5aNWcdBH0DiWfIWkoq9Fy8VEAa/T5v7GCaKvDs9pGBpjQSQsWyKXbwP0Z2RGyU2CSGVzMM6gzrjaxanOK9QbLOqCpTSSIYWfokt+MNrHcQU+9mBTjq20URF7RW6tsM8GvzGRNk0hlkX3ueq86uLpQzRctGBTjN74qBba0WbauIcSl4OIrc+NEwjaFTmuIs0NIG5aoAop8WHOC8cxFAST2XjMF30eEh6/W9Gh0uPor4L5tUqJ/JuI2wcfYLuk1KLDcOUVin79QficX93zbaTPNXWW052ct50B0KnCmZyvQORwOH8gBFgkFe5MO/bqevG9Xpof/QvpCLKEON/fBAW4bEdIIv5qw=="
          cidr_blocks = ["20.117.187.79/32"]
        }
        "cgi-cps" = {
          ssh_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDXxYA8eLvZ1spaM2LUl/EmBhqsLUPUDM1DwjoLD/eDnDnR+DQQ/F7fCNihYML44vgjVmXXMIVkLuvtjJZ5YUmss38UwcMg1FKGG/iMC5CF3nFtDig7sDc3mfMHM5phGM1BPu1lB5K4K/DGnvSUBvim8iOlZV72X832m9QtH3FQXKM7j2O9M9Y65C50OeDJF1KFPjYbsJWRpCDD5eifSV5tfJIgmm9VcLqMLXDelQGuYStok4dh47fF+LhdKHDyNjzc24LvU/p6r5sY26FuVuEoSsL+MGBs/Kiu8KllVkapM0Edztsz/oHh2WwrZFyNMXuuPrMbEoY2KXwzYmvj7mXxxYlj1NLzYxoFVdv1SUhCkBB1WOJMqbbpQT7Nlcyn5n48oUrf+DmRk7PAR/EUZ250mlPhRSqZpaBPghXLg/LXQ/KqVLccVBr3RdlJKhNCIO5NFkE9vfVCgLLKof0LRcAmduI+rn4RrRm1cMH6zdx2ZfVKpWOf4svRg23N+alV/zfUZGdoG8FcEyb6Hcgp/jw5UHGmgUc86HZnfX2Llxz5YCMUDF3Q0qNl2rZR/lS9zxvH+XhrYq8pYvSWilaeU8ZsxJj8GLkxuMrJHt+eT7s+EuHoPoptlMvzqjFKh6ut92sBuXb+XsvtreeBhln9jb+g1xUZnjlArjOxNXRFL7YjUw=="
          cidr_blocks = ["185.157.224.141/32", "185.157.225.141/32"]
        }
        "glenn-barber" = {
          ssh_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCm18Znrr+VfF3K/6frPwEPY7HCBHbUprYpgyCMIykwmn6SL9SEGUehpghd/xjNiFBz27VMTWraZYZ4RFtHQGOPaOzdMIDO+Z9RGX2rt/sjJemA01MOxfW0m9UfZ4wgoh92eYrq7ZnRWbadP2H6W1aUcGBqjh0JJ5VxtSp3wePL4HY90FLI8hMs3xwXpAqCo3ZjYzZCTOpzghwataMEmw5c//vNzGDUa+JGu1U2iGyCJCVaENcKhsKAyK2UbYAkSYBeRjQ7tdkL21Mq4KqHKBVIVlXF6l4fgIFaU11eJthkno5XAGTC3+H0MR8yjGcmufv6Ln2aeZ6zz9e/69wtrrS1qjbgYuPMtTQb7o6FbBwkr0mmfB78xNFNNv5GRzVkwSTiRWF2wjikMaadEJsSH+tKpdmYGgM5THLAyOhuy8Zg0MTsmN2TT3a4i//+T0h8v7mb5w4A87uBDenxIGNSNFKVzUkLL2uSxmn7s0UnuTuDoIthZBUVGYKaEuP2VVWDYWU= glenn.barber@L0429"
          cidr_blocks = ["35.176.93.186/32"]
        }
        "cgi-ssct-sop" = {
          ssh_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDG5zvCi9JcKjpyS6MtVqGdUeOXoMCNtrjWcsFCV/KG2u5HWhFJfjZvGIa1qtu/N9MLOhO3uvFwyGZYNrBe0jD9ji7SQUzWTENFoA4KnsFIPicADG34gxgdIurQo5d1z9/sJXM1Xd4G3QRKW4F7//GHNexX/A0DflubU6nZ7lM+dAXyJ72GzPDiareVFh1/o+2jBcDIRibGt9AZQp8Bu+a8ZyfBP5lEVtXCZ3iJyxh+EzBEH46Uj1KOKne1Tdynj48LMzp/QKnGjV5NuDkKoNwnZrJDhuS8+wdigT1O66bmU7VTLAmWBNO4TX8aCLyP2YgQU1ZTIw/YxQ8Qq8IWIgJC47s2NYp8XJEgcHRZG7McgQW7wrGOH10ttrev2y5jYtooxCcGqZDlM6+j3g0wo0LchA/2DsSbRP54yXvAzePleAupsJSpE4y1eojM7E82nv3J92nJkLyb4p/OahxiqxY4+vIEPdLlv/bqdU2ejU9DMg5ba6HJhxnrJ3N/Pd4mUlRD+sA7vn9LNJMMCBQJDBaTLv5C0vJ3EZZb73fUkshrBjCctumlPhjDiPZmNs50O6cF9a8waPjMGi7DgOHpoZCXOjDkyJu1xmWy8KWgtD7efIS2CFE9l57xzKLaRYABT49lQbGlsdCvpUlHr69C9RxBE0SNV559KEoDyBGcQrauXQ=="
          cidr_blocks = ["20.50.108.242/32", "20.50.109.148/32", "51.11.124.205/32", "51.11.124.216/32"]
        }
      }
      transfer_server_sftp_users_with_egress = {
        "essex-police" = {
          ssh_key               = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpNyYzfbqmy4QkViLRyASRqxrEK7G34o3Bc6Jdp8vK555/oBuAUXUxfavtenZnxuxdxsrBYBSCBFcU4+igeXN/nN2kVfaUlt1xBZBCRUaajinhmt+3CLbr8bWmHR/5vL/DhxHH+j/+gDH5A244XN/ybZQvCGX/ilgKiae8s0tiOZD2hmX0fhRTCohQFG/DIu06gqKIyxUQoHBoBJxjzaDvjqioJgqmD9893DN+Gx1KozmaQWHM+0f7iK1UFp8BkdeFBVkj8TOfx60o/EmAjWQ/U+WSHblaXo0nI+LQKZYkW52uTEnfSkbkyvs/vj8E8+vagwYi0noyTVmb5qReSuk1kyuqEP2ycKIaWKt+Z4LnwxHm7KO51SMMeBgpiFHaUTQWXZHYuU2aXVfFIgJkCtHdEjG7Qe2P8K5XU5rG+CrQ/Y9PxPrKQHk+2nox9dLfCWo2Eho1N85z9/rA7A0oNwsHkjWAl3k87lWdpg7y3VNLzqsMNF4M4HjpQV60MH73dUU= essex-police@kpvmshift04app.netr.ecis.police.uk"
          cidr_blocks           = ["194.74.29.178/32"]
          egress_bucket         = module.bold_egress_bucket.s3_bucket_id
          egress_bucket_kms_key = module.s3_bold_egress_kms.key_arn
        }
      }

      /* DataSync */
      datasync_instance_private_ip = "10.27.128.5"
    }
  }
}
