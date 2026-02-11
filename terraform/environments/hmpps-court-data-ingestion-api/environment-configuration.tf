locals {
  environment_configuration = {
    development = {
      cloud_platform_sqs_queue_name = "calculate-release-dates-team-dev-hmpps_court_data_ingestion_queuev"
    }
    preproduction = {
      cloud_platform_sqs_queue_name = "calculate-release-dates-team-preprod-hmpps_court_data_ingestion_queue"
    }
    production = {
      cloud_platform_sqs_queue_name = "calculate-release-dates-team-prod-hmpps_court_data_ingestion_queue"
    }
  }
}
