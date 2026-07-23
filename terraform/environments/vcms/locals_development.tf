locals {

  baseline_presets_development = {
    options = {}
  }

  # please keep resources in alphabetical order
  baseline_development = {

    # If your DNS records are in Fix 'n' Go, setup will be a 2 step process, see the acm_certificate module readme
    # if making changes, comment out the listeners that use the cert, edit the cert, recreate the listeners
    acm_certificates = {
      dev_vcms_cert = {
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        domain_name                         = "modernisation-platform.service.justice.gov.uk"
        subject_alternate_names = [
          "dev.victim-case-management.service.justice.gov.uk",
          "*.dev.victim-case-management.service.justice.gov.uk",
          "*.dev.vcms.modernisation-platform.service.justice.gov.uk",
          "vcms.hmpps-development.modernisation-platform.service.justice.gov.uk",
          "*.vcms.hmpps-development.modernisation-platform.service.justice.gov.uk",
        ]
        tags = {
          description = "cert for vcms development domains"
        }
      }
    }

    lbs = {
      private = merge(local.lbs.private, {

        listeners = merge(local.lbs.private.listeners, {
          https = merge(local.lbs.private.listeners.https, {
            certificate_names_or_arns = ["dev_vcms_cert"]

            default_action = {
              type = "redirect"
              redirect = {
                host        = "int.vcms.hmpps-development.modernisation-platform.service.justice.gov.uk",
                port        = "443"
                protocol    = "HTTPS"
                status_code = "HTTP_302"
              }
            }

            rules = {
              legacy_redirect = {
                priority = 100
                actions = [{
                  type              = "redirect"
                  redirect = {
                    host        = "int.vcms.hmpps-development.modernisation-platform.service.justice.gov.uk"
                    port        = "443"
                    protocol    = "HTTPS"
                    status_code = "HTTP_301"
                  }
                  target_group_name = "vcms-frontend-private"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [ # max of 5
                        "int.dev.victim-case-management.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
              forward = {
                priority = 200
                actions = [{
                  type              = "forward"
                  target_group_name = "vcms-frontend-private"
                }]
                conditions = [
                  {
                    host_header = {
                      values = [ # max of 5
                        "int.vcms.hmpps-development.modernisation-platform.service.justice.gov.uk",
                      ]
                    }
                  }
                ]
              }
            }
          })
        })
      })
    }

  }
}