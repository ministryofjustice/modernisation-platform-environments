locals {
  eventbridge_guard_duty_malware_protection_for_s3_rules = {
    no_threats_found = {
      name                   = "${local.application_name}-guardduty-no-threats-found"
      description            = "Move clean objects after a successful GuardDuty Malware Protection for S3 scan"
      destination_bucket_key = "clean"
      delete_source          = true
      event_pattern = {
        source = ["aws.guardduty"]
        detail = {
          scanResultDetails = {
            scanResultStatus = ["NO_THREATS_FOUND"]
          }
        }
      }
    }

    threats_found = {
      name                   = "${local.application_name}-guardduty-threats-found"
      description            = "Move quarantined objects after a GuardDuty Malware Protection for S3 detection"
      destination_bucket_key = "quarantine"
      delete_source          = true
      event_pattern = {
        source = ["aws.guardduty"]
        detail = {
          scanResultDetails = {
            scanResultStatus = ["THREATS_FOUND"]
          }
        }
      }
    }

    investigation = {
      name                   = "${local.application_name}-guardduty-investigation"
      description            = "Move objects for investigation when a GuardDuty Malware Protection for S3 scan is skipped or fails"
      destination_bucket_key = "investigation"
      delete_source          = true
      event_pattern = {
        source = ["aws.guardduty"]
        detail = {
          scanResultDetails = {
            scanResultStatus = ["UNSUPPORTED", "ACCESS_DENIED", "FAILED"]
          }
        }
      }
    }
  }
}