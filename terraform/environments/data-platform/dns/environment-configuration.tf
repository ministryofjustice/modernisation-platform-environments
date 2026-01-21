locals {
  environment_configuration = local.environment_configurations[local.environment]
  environment_configurations = {
    development = {
      route53_zone_name = "development.data-platform.service.justice.gov.uk"
      route53_records = {
        llm-gateway-ns = {
          /* 
            Delegate llm-gateway to Cloud Platform 
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
    test = {
      route53_zone_name = "test.data-platform.service.justice.gov.uk"
      route53_records   = {}
    }
    preproduction = {
      route53_zone_name = "preproduction.data-platform.service.justice.gov.uk"
      route53_records   = {}
    }
    production = {
      route53_zone_name = "data-platform.service.justice.gov.uk"
      route53_records = {
        /* Zone Delegation */
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
        github-pages-challenge-txt = {
          type    = "TXT"
          name    = "_github-pages-challenge-ministryofjustice.user-guide"
          ttl     = 300
          records = ["8318341c928cb03ff156af46862430"]
        },
        github-pages-cname = {
          type    = "CNAME"
          name    = "user-guide"
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
  }
}
