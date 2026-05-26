locals {
  environment_configuration = {
    development = {
      cloud_platform_sqs_queue_name = "calculate-release-dates-team-dev-hmpps_court_data_ingestion_queue"
      cloud_platform_secret_id      = "arn:aws:secretsmanager:eu-west-2:754256621582:secret:hmpps-court-data-ingestion-dev-hmac-token-IS6U3E"
    }
    preproduction = {
      cloud_platform_sqs_queue_name = "calculate-release-dates-team-preprod-hmpps_court_data_ingestion_queue"
      cloud_platform_secret_id      = "arn:aws:secretsmanager:eu-west-2:754256621582:secret:hmpps-court-data-ingestion-preprod-hmac-token-j7hLXp"
    }
    production = {
      cloud_platform_sqs_queue_name = "calculate-release-dates-team-prod-hmpps_court_data_ingestion_queue"
      cloud_platform_secret_id      = "arn:aws:secretsmanager:eu-west-2:754256621582:secret:hmpps-court-data-ingestion-prod-hmac-token-V0aSZU"
    }
  }
}
