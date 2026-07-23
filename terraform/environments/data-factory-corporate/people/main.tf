# Guard Duty Detector - see: https://registry.terraform.io/providers/-/aws/latest/docs/resources/guardduty_detector
resource "aws_guardduty_detector" "MyDetector" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
  }
}