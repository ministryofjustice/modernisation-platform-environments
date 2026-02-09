locals {
  environment_configuration = {
    development = {
      cloud_platform_sqs_queue_name = "court-data-ingestion-queue-dev"
    }
    test = {
      cloud_platform_sqs_queue_name = "court-data-ingestion-queue-test"
    }
    preproduction = {
      cloud_platform_sqs_queue_name = "court-data-ingestion-queue-preprod"
    }
    production = {
      cloud_platform_sqs_queue_name = "court-data-ingestion-queue-prod"
    }
  }
}
