module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  create_bus = false

  rules = {
    guardduty-malware-scan-no-threats = {
      description = "Trigger when GuardDuty Malware Protection scans an S3 object and finds no threats"
      event_pattern = jsonencode({
        "source" : ["aws.guardduty"],
        "detail-type" : ["GuardDuty Malware Protection Object Scan Result"],
        "detail" : {
          "scanStatus" : ["COMPLETED"],
          "scanResultDetails" : {
            "scanResultStatus" : ["NO_THREATS_FOUND"]
          }
        }
      })
    },

    guardduty-malware-scan-threats-found = {
      description = "Trigger when GuardDuty Malware Protection scans an S3 object and finds threats"
      event_pattern = jsonencode({
        "source" : ["aws.guardduty"],
        "detail-type" : ["GuardDuty Malware Protection Object Scan Result"],
        "detail" : {
          "scanStatus" : ["COMPLETED"],
          "scanResultDetails" : {
            "scanResultStatus" : ["THREATS_FOUND"]
          }
        }
      })
    },

    guardduty-malware-scan-unsupported = {
      description = "Trigger when GuardDuty Malware Protection skips scanning an S3 object because it's unsupported"
      event_pattern = jsonencode({
        "source" : ["aws.guardduty"],
        "detail-type" : ["GuardDuty Malware Protection Object Scan Result"],
        "detail" : {
          "scanStatus" : ["SKIPPED"],
          "scanResultDetails" : {
            "scanResultStatus" : ["UNSUPPORTED"]
          }
        }
      })
    },

    guardduty-malware-scan-access-denied = {
      description = "Trigger when GuardDuty Malware Protection skips scanning an S3 object due to access denied"
      event_pattern = jsonencode({
        "source" : ["aws.guardduty"],
        "detail-type" : ["GuardDuty Malware Protection Object Scan Result"],
        "detail" : {
          "scanStatus" : ["SKIPPED"],
          "scanResultDetails" : {
            "scanResultStatus" : ["ACCESS_DENIED"]
          }
        }
      })
    },

    guardduty-malware-scan-failed = {
      description = "Trigger when GuardDuty Malware Protection fails to scan an S3 object"
      event_pattern = jsonencode({
        "source" : ["aws.guardduty"],
        "detail-type" : ["GuardDuty Malware Protection Object Scan Result"],
        "detail" : {
          "scanStatus" : ["FAILED"],
          "scanResultDetails" : {
            "scanResultStatus" : ["FAILED"]
          }
        }
      })
    }
  }

  targets = {}
}
