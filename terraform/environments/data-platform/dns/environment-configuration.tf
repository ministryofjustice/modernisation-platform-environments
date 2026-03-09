locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      route53_zones = {
        "development.data-platform.service.justice.gov.uk" = {
          records = {
            llm-gateway-ns = {
              /* 
                Delegate llm-gateway.development.data-platform.service.justice.gov.uk to Cloud Platform 
                https://github.com/ministryofjustice/cloud-platform-environments/blob/main/namespaces/live.cloud-platform.service.justice.gov.uk/data-platform-llm-gateway-development/resources/route53.tf
              */
              type = "NS"
              name = "llm-gateway"
              ttl  = 86400
              records = [
                "ns-1340.awsdns-39.org.",
                "ns-1602.awsdns-08.co.uk.",
                "ns-440.awsdns-55.com.",
                "ns-885.awsdns-46.net."
              ]
            }
          }
        }
        "development.ai-gateway.justice.gov.uk" = {
          records = {}
        }
      }
    }
    test = {
      route53_zones = {
        "test.data-platform.service.justice.gov.uk" = {
          records = {}
        }
        "test.ai-gateway.justice.gov.uk" = {
          records = {}
        }
      }
    }
    preproduction = {
      route53_zones = {
        "preproduction.data-platform.service.justice.gov.uk" = {
          records = {}
        }
        "preproduction.ai-gateway.justice.gov.uk" = {
          records = {}
        }
      }
    }
    production = {
      route53_zones = {
        "data-platform.service.justice.gov.uk" = {
          records = {
            /* Environment Zone Delegation */
            development-ns = {
              type = "NS"
              name = "development"
              ttl  = 86400
              records = [
                "ns-131.awsdns-16.com.",
                "ns-1777.awsdns-30.co.uk.",
                "ns-1189.awsdns-20.org.",
                "ns-1012.awsdns-62.net."
              ]
            },
            preproduction-ns = {
              type = "NS"
              name = "preproduction"
              ttl  = 86400
              records = [
                "ns-1692.awsdns-19.co.uk.",
                "ns-1427.awsdns-50.org.",
                "ns-638.awsdns-15.net.",
                "ns-182.awsdns-22.com."
              ]
            },
            test-ns = {
              type = "NS"
              name = "test"
              ttl  = 86400
              records = [
                "ns-31.awsdns-03.com.",
                "ns-1449.awsdns-53.org.",
                "ns-1599.awsdns-07.co.uk.",
                "ns-674.awsdns-20.net."
              ]
            },
            /* GitHub Pages */
            user-guide-github-pages-challenge-txt = {
              type    = "TXT"
              name    = "_github-pages-challenge-ministryofjustice.user-guide"
              ttl     = 300
              records = ["8318341c928cb03ff156af46862430"]
            },
            user-guide-github-pages-cname = {
              type    = "CNAME"
              name    = "user-guide"
              ttl     = 300
              records = ["ministryofjustice.github.io."]
            }
            manual-github-pages-challenge-txt = {
              type    = "TXT"
              name    = "_github-pages-challenge-ministryofjustice.manual"
              ttl     = 300
              records = ["a0a17e7f4aa71bec7357a6ed2efd5e"]
            },
            manual-github-pages-cname = {
              type    = "CNAME"
              name    = "manual"
              ttl     = 300
              records = ["ministryofjustice.github.io."]
            }
            /* PagerDuty Status Page */
            pagerduty-dkim1-cname = {
              type    = "CNAME"
              name    = "pdt._domainkey.status"
              ttl     = 300
              records = ["pdt.domainkey.u31181182.wl183.sendgrid.net."]
            },
            pagerduty-dkim2-cname = {
              type    = "CNAME"
              name    = "pdt2._domainkey.status"
              ttl     = 300
              records = ["pdt2.domainkey.u31181182.wl183.sendgrid.net."]
            },
            pagerduty-http-trafic-cname = {
              type    = "CNAME"
              name    = "status"
              ttl     = 300
              records = ["cd-4a9d4d61b9ba517b444f76f11a406278.hosted-status.pagerduty.com."]
            },
            pagerduty-mail-cname = {
              type    = "CNAME"
              name    = "em714.status"
              ttl     = 300
              records = ["u31181182.wl183.sendgrid.net."]
            },
            pagerduty-tls-certificate-cname = {
              type    = "CNAME"
              name    = "_701f6977b827d5ad23c4f98802a51bc3.status"
              ttl     = 300
              records = ["_56473aa9b1f7b9aec52ac3d3ea416721.yygwskclfy.acm-validations.aws."]
            }
          }
        }
        "ai-gateway.justice.gov.uk" = {
          records = {
            /* Environment Zone Delegation */
            development-ns = {
              type = "NS"
              name = "development"
              ttl  = 86400
              records = [
                "ns-1336.awsdns-39.org.",
                "ns-970.awsdns-57.net.",
                "ns-2026.awsdns-61.co.uk.",
                "ns-273.awsdns-34.com."
              ]
            },
            test-ns = {
              type = "NS"
              name = "test"
              ttl  = 86400
              records = [
                "ns-602.awsdns-11.net.",
                "ns-1420.awsdns-49.org.",
                "ns-1812.awsdns-34.co.uk.",
                "ns-343.awsdns-42.com."
              ]
            },
            preproduction-ns = {
              type = "NS"
              name = "preproduction"
              ttl  = 86400
              records = [
                "ns-1300.awsdns-34.org.",
                "ns-377.awsdns-47.com.",
                "ns-650.awsdns-17.net.",
                "ns-1772.awsdns-29.co.uk."
              ]
            },
          }
        }
      }
    }
  }
}
