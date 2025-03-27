locals {
  environment_configurations = {
    development = {
      /* QuickSight */
      quicksight_notification_email = "analytical-platform@digital.justice.gov.uk"
    }
    test = {
      /* QuickSight */
      quicksight_notification_email = "analytical-platform@digital.justice.gov.uk"
    }
    production = {
      /* QuickSight */
      quicksight_notification_email = "analytical-platform@digital.justice.gov.uk"
    }
  }
}
